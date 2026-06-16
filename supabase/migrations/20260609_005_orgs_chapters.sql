-- ============================================================================
-- 20260609_005_orgs_chapters.sql
-- Réseau d'Associations Fulɓe : organisations parentes + branches locales,
-- dénormalisation sur members (chapter_id, organization_id) + trigger
-- d'auto-détection par (country, city) + RLS.
-- ============================================================================

-- ── Drop guard (gated par session var) ────────────────────────────────────
-- En Dashboard Supabase, current_setting() ne fonctionne pas comme en CLI,
-- donc ce bloc est un no-op ici. Pour un drop propre, exécutez d'abord
-- `000_dev_reset.sql`.
do $$ begin
  if coalesce(current_setting('fulbe_env', true), 'prod') = 'dev' then
    drop trigger if exists trg_match_member_to_chapter on public.members;
    drop function if exists public.match_member_to_chapter();
    alter table public.members
      drop column if exists chapter_id,
      drop column if exists organization_id;
    drop table if exists public.chapters cascade;
    drop table if exists public.organizations cascade;
  end if;
end $$;

-- ── 1. organizations ──────────────────────────────────────────────────────
create table if not exists public.organizations (
  id           uuid        primary key default gen_random_uuid(),
  name         text        not null,
  country      text        not null,
  description  text,
  status       text        not null default 'active'
                             check (status in ('active', 'pending')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (name, country)
);

create index if not exists idx_organizations_country on public.organizations (country);
create index if not exists idx_organizations_status  on public.organizations (status) where status = 'active';

comment on table public.organizations is
  'Association parente d''un pays (ex: Dental Fulbe Italia, Confédération Fulɓe France).';

-- ── 2. chapters ───────────────────────────────────────────────────────────
create table if not exists public.chapters (
  id              uuid        primary key default gen_random_uuid(),
  organization_id uuid        not null references public.organizations(id) on delete cascade,
  name            text        not null,
  city            text        not null,
  description     text,
  status          text        not null default 'active'
                              check (status in ('active', 'pending')),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (organization_id, city)
);

create index if not exists idx_chapters_organization_id on public.chapters (organization_id);
create index if not exists idx_chapters_city             on public.chapters (city);
create index if not exists idx_chapters_status          on public.chapters (status) where status = 'active';
-- Index composite pour le hot path du trigger (country + city lookup via join)
create index if not exists idx_chapters_org_city_active
  on public.chapters (organization_id, city) where status = 'active';

comment on table public.chapters is
  'Branche locale d''une organisation, identifiée par (organization_id, city).';

-- ── 3. members : ajout des FK dénormalisées ───────────────────────────────
alter table public.members
  add column if not exists organization_id uuid references public.organizations(id) on delete set null,
  add column if not exists chapter_id       uuid references public.chapters(id)       on delete set null;

create index if not exists idx_members_organization_id on public.members (organization_id);
create index if not exists idx_members_chapter_id       on public.members (chapter_id);

-- ── 4. trigger d'auto-détection ───────────────────────────────────────────
-- Quand un member est inséré OU que (country, city) change, on cherche le
-- chapitre actif qui matche et on renseigne les deux FK. Si pas de match,
-- les deux restent NULL (membre "indépendant").
create or replace function public.match_member_to_chapter()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_chapter_id      uuid;
  v_organization_id uuid;
begin
  -- Court-circuit si (country, city) non renseignés
  if new.country is null or new.city is null then
    new.chapter_id      := null;
    new.organization_id := null;
    return new;
  end if;

  select c.id, c.organization_id
    into v_chapter_id, v_organization_id
    from public.chapters c
    join public.organizations o on o.id = c.organization_id
   where o.country = new.country
     and c.city    = new.city
     and c.status  = 'active'
     and o.status  = 'active'
   limit 1;

  new.chapter_id      := v_chapter_id;
  new.organization_id := v_organization_id;
  return new;
end;
$$;

comment on function public.match_member_to_chapter() is
  'Auto-détecte le chapitre (et donc l''organisation) à partir de (country, city) du member.';

drop trigger if exists trg_match_member_to_chapter on public.members;
create trigger trg_match_member_to_chapter
  before insert or update of country, city on public.members
  for each row execute function public.match_member_to_chapter();

-- Backfill : applique le matching aux members existants qui n'ont pas encore
-- les FK renseignées. Idempotent : si déjà set, le SELECT ne retourne rien
-- et les valeurs existantes sont préservées par le WHERE du SELECT INTO
-- (en réalité, on OVERWRITE — c'est l'intention).
update public.members m
   set chapter_id      = sub.chapter_id,
       organization_id = sub.organization_id
  from (
    select m2.id as member_id,
           c.id  as chapter_id,
           c.organization_id
      from public.members m2
      join public.chapters c       on c.city = m2.city
      join public.organizations o  on o.id = c.organization_id and o.country = m2.country
     where c.status = 'active'
       and o.status = 'active'
       and m2.country is not null
       and m2.city    is not null
  ) as sub
 where m.id = sub.member_id;

-- ── 5. updated_at triggers (réutilise tg_set_updated_at de 004) ────────
-- Note : la fonction tg_set_updated_at() est déjà créée dans la migration 004.
-- Les triggers ci-dessous lui sont spécifiques car les tables organisations
-- et chapters sont créées dans cette migration (004 attachait le trigger aux
-- tables existantes à ce moment-là).
do $$ begin
  if not exists (
    select 1 from pg_trigger where tgname = 'trg_set_updated_at_organizations'
  ) then
    create trigger trg_set_updated_at_organizations
      before update on public.organizations
      for each row execute function public.tg_set_updated_at();
  end if;
  if not exists (
    select 1 from pg_trigger where tgname = 'trg_set_updated_at_chapters'
  ) then
    create trigger trg_set_updated_at_chapters
      before update on public.chapters
      for each row execute function public.tg_set_updated_at();
  end if;
end $$;

-- ── 6. RLS ─────────────────────────────────────────────────────────────────
alter table public.organizations enable row level security;
alter table public.chapters       enable row level security;

-- Helpers réutilisés
-- (public.uid() et public.is_admin() sont déjà créés dans 002_rls_policies.sql)

-- ── organizations ──
drop policy if exists "orgs_select_active" on public.organizations;
create policy "orgs_select_active" on public.organizations
  for select using (status = 'active');

drop policy if exists "orgs_select_pending_self" on public.organizations;
create policy "orgs_select_pending_self" on public.organizations
  for select using (
    status = 'pending' and public.is_admin()
  );

drop policy if exists "orgs_insert_authenticated" on public.organizations;
create policy "orgs_insert_authenticated" on public.organizations
  for insert with check (auth.role() = 'authenticated');

drop policy if exists "orgs_update_admin" on public.organizations;
create policy "orgs_update_admin" on public.organizations
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "orgs_delete_admin" on public.organizations;
create policy "orgs_delete_admin" on public.organizations
  for delete using (public.is_admin());

-- ── chapters ──
drop policy if exists "chapters_select_active" on public.chapters;
create policy "chapters_select_active" on public.chapters
  for select using (status = 'active');

drop policy if exists "chapters_select_pending_admin" on public.chapters;
create policy "chapters_select_pending_admin" on public.chapters
  for select using (
    status = 'pending' and public.is_admin()
  );

drop policy if exists "chapters_insert_authenticated" on public.chapters;
create policy "chapters_insert_authenticated" on public.chapters
  for insert with check (auth.role() = 'authenticated');

drop policy if exists "chapters_update_admin" on public.chapters;
create policy "chapters_update_admin" on public.chapters
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "chapters_delete_admin" on public.chapters;
create policy "chapters_delete_admin" on public.chapters
  for delete using (public.is_admin());

-- ── 7. Realtime : notifier les nouveaux chapitres aux clients ────────────
do $$ begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public'
       and tablename = 'chapters'
  ) then
    execute 'alter publication supabase_realtime add table public.chapters';
  end if;
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public'
       and tablename = 'organizations'
  ) then
    execute 'alter publication supabase_realtime add table public.organizations';
  end if;
end $$;
