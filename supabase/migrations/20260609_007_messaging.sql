-- =============================================================================
-- Fulɓe Connect — Messaging System (conversations, messages, participants)
-- =============================================================================
-- Date    : 2026-06-09
-- Purpose : Tables de messagerie directe et de groupe, avec RLS.
-- Order   : 7/7 (run after 006_seed_organizations)
-- =============================================================================

-- ── 1. conversations ─────────────────────────────────────────────────────────
create table if not exists public.conversations (
  id         uuid        primary key default gen_random_uuid(),
  type       text        not null check (type in ('direct', 'group')),
  name       text,                          -- null for direct (computed from peers)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.conversations is
  'Conversation : direct (1-to-1) ou groupe. Pour les directs, le name est NULL (construit côté client).';

-- ── 2. conversation_participants ─────────────────────────────────────────────
create table if not exists public.conversation_participants (
  id              uuid        primary key default gen_random_uuid(),
  conversation_id uuid        not null references public.conversations(id) on delete cascade,
  member_id       uuid        not null references public.members(id) on delete cascade,
  last_read_at    timestamptz,            -- NULL si jamais lu
  created_at      timestamptz not null default now(),
  unique (conversation_id, member_id)
);

create index if not exists idx_conv_participants_conv on public.conversation_participants (conversation_id);
create index if not exists idx_conv_participants_member on public.conversation_participants (member_id);

comment on table public.conversation_participants is
  'Lien n-n entre conversations et members. last_read_at sert au compteur de messages non lus.';

-- ── 3. messages ──────────────────────────────────────────────────────────────
create table if not exists public.messages (
  id              uuid        primary key default gen_random_uuid(),
  conversation_id uuid        not null references public.conversations(id) on delete cascade,
  sender_id       uuid        not null references public.members(id) on delete cascade,
  content         text        not null,
  created_at      timestamptz not null default now()
);

create index if not exists idx_messages_conv_created
  on public.messages (conversation_id, created_at desc);

comment on table public.messages is
  'Messages individuels d''une conversation. Chaque ligne = 1 message.';

-- ── 4. updated_at trigger (conversations) ────────────────────────────────────
-- Réutilise tg_set_updated_at de la migration 004
do $$ begin
  if not exists (
    select 1 from pg_trigger where tgname = 'trg_set_updated_at_conversations'
  ) then
    create trigger trg_set_updated_at_conversations
      before update on public.conversations
      for each row execute function public.tg_set_updated_at();
  end if;
end $$;

-- ── 5. RLS ───────────────────────────────────────────────────────────────────
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;

-- Helper : vérifie qu'un utilisateur auth participe à une conversation donnée.
-- Note : on joint via members pour traduire auth.uid() (auth.users.id)
-- en members.id (car conversation_participants.member_id référence members.id).
create or replace function public.is_participant(conv_id uuid, auth_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_participants cp
    join public.members m on m.id = cp.member_id
    where cp.conversation_id = conv_id and m.user_id = auth_user_id
  );
$$;

-- ── conversations ──
drop policy if exists "conv_select_participant" on public.conversations;
create policy "conv_select_participant" on public.conversations
  for select using (
    public.is_participant(id, auth.uid())
  );

drop policy if exists "conv_insert_authenticated" on public.conversations;
create policy "conv_insert_authenticated" on public.conversations
  for insert with check (auth.role() = 'authenticated');

-- ── conversation_participants ──
drop policy if exists "cp_select_own" on public.conversation_participants;
create policy "cp_select_own" on public.conversation_participants
  for select using (
    public.is_participant(conversation_id, auth.uid())
  );

drop policy if exists "cp_insert_self" on public.conversation_participants;
create policy "cp_insert_self" on public.conversation_participants
  for insert with check (
    auth.role() = 'authenticated'
  );

-- ── messages ──
drop policy if exists "msg_select_participant" on public.messages;
create policy "msg_select_participant" on public.messages
  for select using (
    public.is_participant(conversation_id, auth.uid())
  );

drop policy if exists "msg_insert_participant" on public.messages;
create policy "msg_insert_participant" on public.messages
  for insert with check (
    public.is_participant(conversation_id, auth.uid())
    and exists (
      select 1 from public.members m
      where m.id = sender_id and m.user_id = auth.uid()
    )
  );

-- ── 6. Realtime ──────────────────────────────────────────────────────────────
do $$ begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public'
       and tablename = 'messages'
  ) then
    execute 'alter publication supabase_realtime add table public.messages';
  end if;
end $$;

-- =============================================================================
-- Done.
-- =============================================================================
-- Après cette migration, le schéma complet contient 18 tables + 4 vues.
