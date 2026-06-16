-- =============================================================================
-- Fulɓe Connect — Group Calls (Multi-Participant Audio/Video Calls)
-- =============================================================================
-- Date    : 2026-06-15
-- Purpose : Tables de signalisation pour les appels de groupe via Agora.
-- Order   : Après 20260615_031_member_fcm_tokens.sql.
--
-- Design  :
--   - group_calls : session d'appel de groupe (canal Agora, type, statut).
--   - group_call_participants : membres invités/rejoints/left/rejected.
--   - La signalisation temps réel se fait via Supabase Realtime sur
--     group_call_participants.
-- =============================================================================

-- ── 1. group_calls ──────────────────────────────────────────────────────────
create table if not exists public.group_calls (
  id            uuid        primary key default gen_random_uuid(),
  conversation_id uuid      not null references public.conversations(id) on delete cascade,
  caller_id     uuid        not null references public.members(id) on delete cascade,
  call_type     text        not null check (call_type in ('audio', 'video')),
  status        text        not null default 'pending'
                              check (status in ('pending', 'active', 'ended', 'cancelled')),
  agora_channel text        not null,
  created_at    timestamptz not null default now(),
  ended_at      timestamptz
);

-- Index pour les requêtes fréquentes
create index if not exists idx_group_calls_conversation on public.group_calls (conversation_id);
create index if not exists idx_group_calls_caller on public.group_calls (caller_id);
create index if not exists idx_group_calls_status on public.group_calls (status);

comment on table public.group_calls is
  'Sessions d''appels de groupe audio/vidéo. Le canal Agora est partagé par tous les participants.';

-- ── 2. group_call_participants ─────────────────────────────────────────────
create table if not exists public.group_call_participants (
  id            uuid        primary key default gen_random_uuid(),
  group_call_id uuid        not null references public.group_calls(id) on delete cascade,
  member_id     uuid        not null references public.members(id) on delete cascade,
  status        text        not null default 'invited'
                              check (status in ('invited', 'joined', 'left', 'rejected')),
  invited_at    timestamptz not null default now(),
  joined_at     timestamptz,
  left_at       timestamptz,
  unique (group_call_id, member_id)
);

-- Index
create index if not exists idx_group_call_participants_call on public.group_call_participants (group_call_id);
create index if not exists idx_group_call_participants_member on public.group_call_participants (member_id);
create index if not exists idx_group_call_participants_status on public.group_call_participants (status);

comment on table public.group_call_participants is
  'Participants d''un appel de groupe. Un membre ne peut être qu''une fois par appel.';

-- ── 3. RLS ───────────────────────────────────────────────────────────────────
alter table public.group_calls enable row level security;
alter table public.group_call_participants enable row level security;

-- group_calls SELECT : participants de l'appel ou caller
drop policy if exists "group_calls_select" on public.group_calls;
create policy "group_calls_select" on public.group_calls
  for select using (
    caller_id = (select id from public.members where user_id = auth.uid())
    or exists (
      select 1 from public.group_call_participants
      where group_call_id = public.group_calls.id
        and member_id = (select id from public.members where user_id = auth.uid())
    )
  );

-- group_calls INSERT : le caller peut créer
drop policy if exists "group_calls_insert" on public.group_calls;
create policy "group_calls_insert" on public.group_calls
  for insert with check (
    caller_id = (select id from public.members where user_id = auth.uid())
  );

-- group_calls UPDATE : caller ou participants
drop policy if exists "group_calls_update" on public.group_calls;
create policy "group_calls_update" on public.group_calls
  for update using (
    caller_id = (select id from public.members where user_id = auth.uid())
    or exists (
      select 1 from public.group_call_participants
      where group_call_id = public.group_calls.id
        and member_id = (select id from public.members where user_id = auth.uid())
    )
  )
  with check (
    caller_id = (select id from public.members where user_id = auth.uid())
    or exists (
      select 1 from public.group_call_participants
      where group_call_id = public.group_calls.id
        and member_id = (select id from public.members where user_id = auth.uid())
    )
  );

-- group_call_participants SELECT : participants de l'appel
drop policy if exists "group_call_participants_select" on public.group_call_participants;
create policy "group_call_participants_select" on public.group_call_participants
  for select using (
    member_id = (select id from public.members where user_id = auth.uid())
    or exists (
      select 1 from public.group_calls
      where id = public.group_call_participants.group_call_id
        and caller_id = (select id from public.members where user_id = auth.uid())
    )
  );

-- group_call_participants INSERT : caller ou soi-même (accept invitation)
drop policy if exists "group_call_participants_insert" on public.group_call_participants;
create policy "group_call_participants_insert" on public.group_call_participants
  for insert with check (
    member_id = (select id from public.members where user_id = auth.uid())
    or exists (
      select 1 from public.group_calls
      where id = public.group_call_participants.group_call_id
        and caller_id = (select id from public.members where user_id = auth.uid())
    )
  );

-- group_call_participants UPDATE : soi-même ou caller
drop policy if exists "group_call_participants_update" on public.group_call_participants;
create policy "group_call_participants_update" on public.group_call_participants
  for update using (
    member_id = (select id from public.members where user_id = auth.uid())
    or exists (
      select 1 from public.group_calls
      where id = public.group_call_participants.group_call_id
        and caller_id = (select id from public.members where user_id = auth.uid())
    )
  )
  with check (
    member_id = (select id from public.members where user_id = auth.uid())
    or exists (
      select 1 from public.group_calls
      where id = public.group_call_participants.group_call_id
        and caller_id = (select id from public.members where user_id = auth.uid())
    )
  );

-- Realtime : ajoute les tables à la publication supabase_realtime.
do $$ begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public'
       and tablename = 'group_calls'
  ) then
    execute 'alter publication supabase_realtime add table public.group_calls';
  end if;
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public'
       and tablename = 'group_call_participants'
  ) then
    execute 'alter publication supabase_realtime add table public.group_call_participants';
  end if;
end $$;

-- =============================================================================
-- Done.
-- =============================================================================
