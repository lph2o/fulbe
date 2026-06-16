-- =============================================================================
-- Fulɓe Connect — Community Invite Links
-- =============================================================================
-- Date    : 2026-06-16
-- Purpose : Liens d'invitation aux groupes/communautés avec code court unique.
-- Order   : Après 20260616_035_communities.sql
--
-- Design  :
--   - community_invites : code unique par communauté (max 1 code actif à la fois)
--   - Fonction de génération de code aléatoire hex (12 chars)
--   - RLS : seuls les admins peuvent créer/supprimer, les membres authentifiés
--     peuvent consommer un code pour rejoindre
-- =============================================================================

-- ── 1. community_invites ─────────────────────────────────────────────────────
create table if not exists public.community_invites (
  id            uuid        primary key default gen_random_uuid(),
  community_id  uuid        not null references public.communities(id) on delete cascade,
  code          text        not null,
  created_by    uuid        not null references public.members(id) on delete cascade,
  created_at    timestamptz not null default now(),
  unique (community_id),
  unique (code)
);

create index if not exists idx_community_invites_code on public.community_invites (code);
create index if not exists idx_community_invites_community on public.community_invites (community_id);

comment on table public.community_invites is
  'Code d''invitation unique par communauté. Généré par un admin.';

-- ── 2. Helper : génération de code aléatoire ──────────────────────────────────
-- Utilise gen_random_uuid() (disponible nativement dans PG 13+ / Supabase)
-- plutôt que gen_random_bytes() qui nécessite l'extension pgcrypto.
create or replace function public.gen_invite_code()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select substring(replace(gen_random_uuid()::text, '-', ''), 1, 12);
$$;

comment on function public.gen_invite_code() is
  'Génère un code hex de 12 caractères pour les liens d''invitation.';

-- ── 3. RLS ───────────────────────────────────────────────────────────────────

alter table public.community_invites enable row level security;

-- Un admin/modérateur peut voir les codes d'invitation de son groupe
drop policy if exists "ci_select_admin" on public.community_invites;
create policy "ci_select_admin" on public.community_invites
  for select using (public.is_community_admin(community_id));

-- Un admin peut créer un code pour son groupe
drop policy if exists "ci_insert_admin" on public.community_invites;
create policy "ci_insert_admin" on public.community_invites
  for insert with check (public.is_community_admin(community_id));

-- Un admin peut supprimer/régénérer le code de son groupe
drop policy if exists "ci_delete_admin" on public.community_invites;
create policy "ci_delete_admin" on public.community_invites
  for delete using (public.is_community_admin(community_id));

-- ── 4. Fonction publique : rejoindre via code d'invitation ─────────────────
-- Cette fonction security definer contourne RLS pour l'insertion dans
-- community_members quand un utilisateur valide un code d'invitation.
create or replace function public.join_community_by_invite_code(invite_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_community_id uuid;
  v_member_id    uuid;
begin
  -- Récupère l'ID du membre courant
  select id into v_member_id
    from public.members
   where user_id = auth.uid();

  if v_member_id is null then
    raise exception 'NOT_AUTHENTICATED' using hint = 'Tu dois être connecté pour rejoindre un groupe.';
  end if;

  -- Trouve la communauté associée au code
  select community_id into v_community_id
    from public.community_invites
   where code = invite_code;

  if v_community_id is null then
    raise exception 'INVALID_CODE' using hint = 'Ce code d''invitation est invalide ou a expiré.';
  end if;

  -- Vérifie que l'utilisateur n'est pas déjà membre
  if exists (
    select 1 from public.community_members
     where community_id = v_community_id
       and member_id = v_member_id
       and status = 'active'
  ) then
    raise exception 'ALREADY_MEMBER' using hint = 'Tu es déjà membre de ce groupe.';
  end if;

  -- Insère l'adhésion (la RLS est contournée via security definer)
  insert into public.community_members (community_id, member_id, role, status)
  values (v_community_id, v_member_id, 'member', 'active');

  return v_community_id;
end;
$$;

comment on function public.join_community_by_invite_code(text) is
  'Permet à un utilisateur authentifié de rejoindre une communauté via un code d''invitation. Retourne l''ID de la communauté.';

-- ── 5. Realtime ──────────────────────────────────────────────────────────────
do $$ begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public'
       and tablename = 'community_invites'
  ) then
    execute 'alter publication supabase_realtime add table public.community_invites';
  end if;
end $$;

-- =============================================================================
-- Done.
-- =============================================================================
