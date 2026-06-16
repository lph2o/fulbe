-- =============================================================================
-- Fulɓe Connect — Member Presence & Last Seen
-- =============================================================================
-- Date    : 2026-06-17
-- Purpose : Add online presence tracking with last_seen column, heartbeat RPC,
--           and Realtime broadcasting for the chat presence indicator.
-- Order   : Run after all previous migrations.
--
-- Architecture:
--   1. members.last_seen (timestamptz) — mise à jour par heartbeat client
--   2. RPC update_last_seen() — appelée périodiquement par l'app
--   3. Realtime publication via supabase_realtime → l'app écoute les changes
-- =============================================================================

-- =============================================================================
-- 1. Ajout de la colonne last_seen à la table members
-- =============================================================================
alter table public.members
  add column if not exists last_seen timestamptz;

-- Index sur last_seen pour les requêtes de type "qui est en ligne ?"
create index if not exists idx_members_last_seen on public.members(last_seen desc);

-- =============================================================================
-- 2. RPC : update_last_seen()
-- =============================================================================
-- Appelée périodiquement par l'application mobile (toutes les 60 secondes).
-- Met à jour `last_seen` pour l'utilisateur authentifié.
-- Retourne le timestamp mis à jour.
create or replace function public.update_last_seen()
returns timestamptz
language plpgsql
security definer set search_path = public
as $$
declare
  now_ts timestamptz := now();
begin
  update public.members
     set last_seen = now_ts
   where user_id = auth.uid();
  return now_ts;
end;
$$;

-- =============================================================================
-- 3. Realtime : activer la publication sur la table members
-- =============================================================================
-- Permet à l'app de s'abonner aux changements de last_seen des autres membres.
alter publication supabase_realtime add table public.members;

-- =============================================================================
-- 4. Ajouter last_seen à la vue v_member_profiles
-- =============================================================================
-- Recrée la vue pour inclure last_seen, afin que l'app puisse l'obtenir
-- en un seul appel quand elle charge un profil.
create or replace view public.v_member_profiles
with (security_invoker = true) as
select
  m.id,
  m.user_id,
  m.full_name,
  m.profession,
  m.city,
  m.country,
  m.avatar_url,
  m.cover_url,
  m.initials,
  m.is_verified,
  m.linkedin,
  m.bio,
  m.last_seen,
  m.created_at,
  m.updated_at,
  coalesce(
    (
      select array_agg(s.skill order by s.skill)
      from public.member_skills s
      where s.member_id = m.id
    ),
    '{}'::text[]
  ) as skills
from public.members m;

comment on view public.v_member_profiles is
  'Member profiles flattened with their skills and last_seen. Use this for directory, presence, and profile screens.';

-- =============================================================================
-- Done.
-- =============================================================================
