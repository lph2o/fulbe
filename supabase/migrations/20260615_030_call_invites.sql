-- =============================================================================
-- Fulɓe Connect — Call Invites (1-to-1 Audio/Video Calls)
-- =============================================================================
-- Date    : 2026-06-15
-- Purpose : Table de signalisation pour les appels audio/vidéo 1-to-1 via Agora.
-- Order   : Après toutes les migrations existantes.
--
-- Design  :
--   - call_invites : stocke les invitations d'appel avec leur statut.
--   - La signalisation temps réel se fait via Supabase Realtime (broadcast
--     ou changes sur call_invites).
--   - Le token Agora est généré côté client en dev (token = 0), et côté
--     serveur (Edge Function) en production.
-- =============================================================================

-- ── 1. call_invites ─────────────────────────────────────────────────────────
create table if not exists public.call_invites (
  id              uuid        primary key default gen_random_uuid(),
  caller_id       uuid        not null references public.members(id) on delete cascade,
  callee_id       uuid        not null references public.members(id) on delete cascade,
  conversation_id uuid        not null references public.conversations(id) on delete cascade,
  call_type       text        not null check (call_type in ('audio', 'video')),
  status          text        not null default 'pending'
                              check (status in ('pending', 'accepted', 'rejected', 'ended', 'missed', 'cancelled')),
  agora_channel   text        not null,   -- nom du canal Agora (unique par appel)
  started_at      timestamptz,
  ended_at        timestamptz,
  created_at      timestamptz not null default now()
);

-- Index pour les requêtes fréquentes : trouver les appels en cours d'un membre.
create index if not exists idx_call_invites_callee_status on public.call_invites (callee_id, status);
create index if not exists idx_call_invites_caller_status on public.call_invites (caller_id, status);
create index if not exists idx_call_invites_conversation on public.call_invites (conversation_id);

comment on table public.call_invites is
  'Invitations d''appels audio/vidéo 1-to-1. Le statut passe de pending → accepted/rejected → ended.';

-- ── 2. RLS ───────────────────────────────────────────────────────────────────
alter table public.call_invites enable row level security;

-- SELECT : les deux participants de l'appel peuvent voir la ligne.
drop policy if exists "call_invites_select_participants" on public.call_invites;
create policy "call_invites_select_participants" on public.call_invites
  for select using (
    caller_id = (select id from public.members where user_id = auth.uid())
    or callee_id = (select id from public.members where user_id = auth.uid())
  );

-- INSERT : l'appelant peut créer une invitation.
drop policy if exists "call_invites_insert_caller" on public.call_invites;
create policy "call_invites_insert_caller" on public.call_invites
  for insert with check (
    caller_id = (select id from public.members where user_id = auth.uid())
  );

-- UPDATE : les deux participants peuvent modifier (accepter, rejeter, terminer).
drop policy if exists "call_invites_update_participants" on public.call_invites;
create policy "call_invites_update_participants" on public.call_invites
  for update using (
    caller_id = (select id from public.members where user_id = auth.uid())
    or callee_id = (select id from public.members where user_id = auth.uid())
  )
  with check (
    caller_id = (select id from public.members where user_id = auth.uid())
    or callee_id = (select id from public.members where user_id = auth.uid())
  );

-- Realtime : ajoute la table à la publication supabase_realtime.
do $$ begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public'
       and tablename = 'call_invites'
  ) then
    execute 'alter publication supabase_realtime add table public.call_invites';
  end if;
end $$;

-- =============================================================================
-- Done.
-- =============================================================================
