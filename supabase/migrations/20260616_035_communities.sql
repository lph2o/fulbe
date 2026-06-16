-- =============================================================================
-- Fulɓe Connect — Communities / Groups Feature
-- =============================================================================
-- Date    : 2026-06-16
-- Purpose : Tables pour les groupes/communautés libres (feed, membres, rôles).
-- Order   : Après 20260616_034_fix_group_calls_rls_infinite_recursion.sql
--
-- Design  :
--   - communities : groupe/communauté avec catégorie, visibilité privée/publique
--   - community_members : adhésion avec rôles (admin, moderator, member)
--   - community_posts : publications dans le feed du groupe
--   - Trigger : maintient member_count dénormalisé sur communities
-- =============================================================================

-- ── 1. communities ───────────────────────────────────────────────────────────
create table if not exists public.communities (
  id              uuid        primary key default gen_random_uuid(),
  name            text        not null,
  description     text        not null default '',
  cover_url       text,
  category        text        not null,
  visibility      text        not null default 'public'
                              check (visibility in ('public', 'private')),
  member_count    integer     not null default 0,
  created_by      uuid        not null references public.members(id) on delete cascade,
  organization_id uuid        references public.organizations(id) on delete set null,
  chapter_id      uuid        references public.chapters(id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_communities_category   on public.communities (category);
create index if not exists idx_communities_visibility on public.communities (visibility);
create index if not exists idx_communities_created_by on public.communities (created_by);

comment on table public.communities is
  'Groupe/communauté avec feed, membres et rôles. Peut être lié à une organization ou chapter.';

-- ── 2. community_members ─────────────────────────────────────────────────────
create table if not exists public.community_members (
  id            uuid        primary key default gen_random_uuid(),
  community_id  uuid        not null references public.communities(id) on delete cascade,
  member_id     uuid        not null references public.members(id) on delete cascade,
  role          text        not null default 'member'
                            check (role in ('admin', 'moderator', 'member')),
  status        text        not null default 'active'
                            check (status in ('active', 'pending')),
  joined_at     timestamptz not null default now(),
  unique (community_id, member_id)
);

create index if not exists idx_community_members_community on public.community_members (community_id);
create index if not exists idx_community_members_member    on public.community_members (member_id);
create index if not exists idx_community_members_role      on public.community_members (community_id, role);

comment on table public.community_members is
  'Adhésion à un groupe. role = admin|moderator|member, status = active|pending (privé).';

-- ── 3. community_posts ───────────────────────────────────────────────────────
create table if not exists public.community_posts (
  id            uuid        primary key default gen_random_uuid(),
  community_id  uuid        not null references public.communities(id) on delete cascade,
  author_id     uuid        not null references public.members(id) on delete cascade,
  content       text        not null,
  image_url     text,
  created_at    timestamptz not null default now()
);

create index if not exists idx_community_posts_community on public.community_posts (community_id, created_at desc);
create index if not exists idx_community_posts_author    on public.community_posts (author_id);

comment on table public.community_posts is
  'Publications dans le feed d''un groupe.';

-- ── 4. Triggers ─────────────────────────────────────────────────────────────

-- Trigger updated_at sur communities
do $$ begin
  if not exists (
    select 1 from pg_trigger where tgname = 'trg_set_updated_at_communities'
  ) then
    create trigger trg_set_updated_at_communities
      before update on public.communities
      for each row execute function public.tg_set_updated_at();
  end if;
end $$;

-- Maintient member_count dénormalisé sur communities
create or replace function public.tg_community_member_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.communities
       set member_count = member_count + 1
     where id = new.community_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.communities
       set member_count = member_count - 1
     where id = old.community_id;
    return old;
  end if;
  return null;
end;
$$;

comment on function public.tg_community_member_count() is
  'Met à jour member_count sur communities après insert/delete sur community_members.';

drop trigger if exists trg_community_member_count on public.community_members;
create trigger trg_community_member_count
  after insert or delete on public.community_members
  for each row execute function public.tg_community_member_count();

-- ── 5. RLS ───────────────────────────────────────────────────────────────────

alter table public.communities        enable row level security;
alter table public.community_members  enable row level security;
alter table public.community_posts    enable row level security;

-- ── Helper : l'utilisateur courant est-il membre actif d'un groupe ?
-- (security definer pour éviter les problèmes de récursion RLS)
create or replace function public.is_community_member(community_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.community_members cm
    join public.members m on m.id = cm.member_id
    where cm.community_id = $1
      and cm.status = 'active'
      and m.user_id = auth.uid()
  );
$$;

-- ── Helper : l'utilisateur courant est-il admin/modérateur du groupe ?
create or replace function public.is_community_admin(community_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.community_members cm
    join public.members m on m.id = cm.member_id
    where cm.community_id = $1
      and cm.role in ('admin', 'moderator')
      and cm.status = 'active'
      and m.user_id = auth.uid()
  );
$$;

-- ── communities policies ──

drop policy if exists "communities_select_public" on public.communities;
create policy "communities_select_public" on public.communities
  for select using (visibility = 'public' or public.is_community_member(id));

drop policy if exists "communities_insert_authenticated" on public.communities;
create policy "communities_insert_authenticated" on public.communities
  for insert with check (auth.role() = 'authenticated');

drop policy if exists "communities_update_owner_admin" on public.communities;
create policy "communities_update_owner_admin" on public.communities
  for update using (
    exists (select 1 from public.members m where m.id = created_by and m.user_id = auth.uid())
    or public.is_community_admin(id)
  ) with check (
    exists (select 1 from public.members m where m.id = created_by and m.user_id = auth.uid())
    or public.is_community_admin(id)
  );

drop policy if exists "communities_delete_owner_admin" on public.communities;
create policy "communities_delete_owner_admin" on public.communities
  for delete using (
    exists (select 1 from public.members m where m.id = created_by and m.user_id = auth.uid())
    or public.is_community_admin(id)
  );

-- ── community_members policies ──

drop policy if exists "cm_select_member" on public.community_members;
create policy "cm_select_member" on public.community_members
  for select using (public.is_community_member(community_id) or public.is_community_admin(community_id));

drop policy if exists "cm_insert_self" on public.community_members;
create policy "cm_insert_self" on public.community_members
  for insert with check (
    exists (select 1 from public.members m where m.id = member_id and m.user_id = auth.uid())
    and (
      -- Pour les groupes publics, rejoindre directement
      exists (select 1 from public.communities c where c.id = community_id and c.visibility = 'public')
      or
      -- Pour les groupes privés, le créateur/admin peut inviter
      public.is_community_admin(community_id)
    )
  );

drop policy if exists "cm_update_admin" on public.community_members;
create policy "cm_update_admin" on public.community_members
  for update using (public.is_community_admin(community_id))
  with check (public.is_community_admin(community_id));

drop policy if exists "cm_delete_self_or_admin" on public.community_members;
create policy "cm_delete_self_or_admin" on public.community_members
  for delete using (
    public.is_community_admin(community_id)
    or exists (select 1 from public.members m where m.id = member_id and m.user_id = auth.uid())
  );

-- ── community_posts policies ──

drop policy if exists "cp_select_member" on public.community_posts;
create policy "cp_select_member" on public.community_posts
  for select using (public.is_community_member(community_id));

drop policy if exists "cp_insert_member" on public.community_posts;
create policy "cp_insert_member" on public.community_posts
  for insert with check (
    public.is_community_member(community_id)
    and exists (select 1 from public.members m where m.id = author_id and m.user_id = auth.uid())
  );

drop policy if exists "cp_delete_author_admin" on public.community_posts;
create policy "cp_delete_author_admin" on public.community_posts
  for delete using (
    public.is_community_admin(community_id)
    or exists (select 1 from public.members m where m.id = author_id and m.user_id = auth.uid())
  );

-- ── 6. Realtime ──────────────────────────────────────────────────────────────
do $$ begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public'
       and tablename = 'community_posts'
  ) then
    execute 'alter publication supabase_realtime add table public.community_posts';
  end if;
end $$;

-- =============================================================================
-- Done.
-- =============================================================================
