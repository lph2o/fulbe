-- =============================================================================
-- Fulɓe Connect — Reset & Recreate Messaging (complet, self-contained)
-- =============================================================================
-- Date    : 2026-06-14
-- Purpose : Recrée TOUT le sous-système de messagerie en un seul script.
--           Tables : conversations, conversation_participants, messages
--           Inclut : colonnes, contraintes, index, RLS, triggers, grants,
--                    Realtime, et la colonne metadata pour les post_shares.
-- Usage   : Copier-coller dans le SQL Editor de Supabase → RUN.
-- ⚠️       Ce script DROP les tables existantes (les messages seront perdus).
-- =============================================================================

-- ── 0. Nettoyage ────────────────────────────────────────────────────────────
-- On supprime d'abord les policies (qui dépendent de is_participant),
-- puis la fonction avec CASCADE, puis les tables.
drop policy if exists conv_select_participant on public.conversations;
drop policy if exists conv_insert_authenticated on public.conversations;
drop policy if exists cp_select_own on public.conversation_participants;
drop policy if exists cp_insert_self on public.conversation_participants;
drop policy if exists msg_select_participant on public.messages;
drop policy if exists msg_insert_participant on public.messages;

drop trigger if exists trg_message_bump_conversation on public.messages;
drop trigger if exists trg_message_bump_conversation_delete on public.messages;
drop trigger if exists trg_set_updated_at_conversations on public.conversations;

drop function if exists public.tg_message_bump_conversation cascade;
drop function if exists public.is_participant(uuid, uuid) cascade;
drop function if exists public.tg_set_updated_at cascade;

drop table if exists public.messages cascade;
drop table if exists public.conversation_participants cascade;
drop table if exists public.conversations cascade;

-- ── 1. conversations ────────────────────────────────────────────────────────
create table public.conversations (
  id         uuid        primary key default gen_random_uuid(),
  type       text        not null check (type in ('direct', 'group')),
  name       text,                          -- null for direct (computed from peers)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.conversations is
  'Conversation : direct (1-to-1) ou groupe. Pour les directs, le name est NULL (construit côté client).';

-- ── 2. conversation_participants ────────────────────────────────────────────
create table public.conversation_participants (
  id              uuid        primary key default gen_random_uuid(),
  conversation_id uuid        not null references public.conversations(id) on delete cascade,
  member_id       uuid        not null references public.members(id) on delete cascade,
  last_read_at    timestamptz,            -- NULL si jamais lu
  created_at      timestamptz not null default now(),
  unique (conversation_id, member_id)
);

create index idx_conv_participants_conv on public.conversation_participants (conversation_id);
create index idx_conv_participants_member on public.conversation_participants (member_id);

comment on table public.conversation_participants is
  'Lien n-n entre conversations et members. last_read_at sert au compteur de messages non lus.';

-- ── 3. messages (avec colonne metadata pour post_share) ─────────────────────
create table public.messages (
  id              uuid        primary key default gen_random_uuid(),
  conversation_id uuid        not null references public.conversations(id) on delete cascade,
  sender_id       uuid        not null references public.members(id) on delete cascade,
  content         text        not null default '',
  metadata        jsonb       default '{}'::jsonb,
  created_at      timestamptz not null default now()
);

create index idx_messages_conv_created
  on public.messages (conversation_id, created_at desc);

comment on table public.messages is
  'Messages individuels. metadata stocke msg_type et post_id pour les partages de post.';

-- ── 4. Trigger updated_at (conversations) ───────────────────────────────────
create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger trg_set_updated_at_conversations
  before update on public.conversations
  for each row execute function public.tg_set_updated_at();

-- ── 5. Trigger bump conversation.updated_at on new/delete message ───────────
create or replace function public.tg_message_bump_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  _conv_id uuid;
begin
  if (tg_op = 'DELETE') then
    _conv_id := old.conversation_id;
  else
    _conv_id := new.conversation_id;
  end if;

  update public.conversations
     set updated_at = now()
   where id = _conv_id;
  return coalesce(new, old);
end;
$$;

create trigger trg_message_bump_conversation
  after insert on public.messages
  for each row execute function public.tg_message_bump_conversation();

create trigger trg_message_bump_conversation_delete
  after delete on public.messages
  for each row execute function public.tg_message_bump_conversation();

-- ── 6. RLS ──────────────────────────────────────────────────────────────────
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;

-- Helper : vérifie qu'un utilisateur auth participe à une conversation donnée.
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

-- conversations : SELECT si participant, INSERT si authentifié
create policy "conv_select_participant" on public.conversations
  for select using (
    public.is_participant(id, auth.uid())
    or not exists (
      select 1 from public.conversation_participants cp
      where cp.conversation_id = id
    )
  );

create policy "conv_insert_authenticated" on public.conversations
  for insert with check (auth.uid() is not null);

-- conversation_participants : SELECT si participant, INSERT si authentifié
create policy "cp_select_own" on public.conversation_participants
  for select using (
    public.is_participant(conversation_id, auth.uid())
  );

create policy "cp_insert_self" on public.conversation_participants
  for insert with check (
    auth.uid() is not null
  );

-- messages : SELECT si participant, INSERT si participant + propriétaire
create policy "msg_select_participant" on public.messages
  for select using (
    public.is_participant(conversation_id, auth.uid())
  );

create policy "msg_insert_participant" on public.messages
  for insert with check (
    public.is_participant(conversation_id, auth.uid())
    and exists (
      select 1 from public.members m
      where m.id = sender_id and m.user_id = auth.uid()
    )
  );

-- ── 7. Grants ───────────────────────────────────────────────────────────────
grant select, insert, update, delete on
  public.conversations,
  public.conversation_participants,
  public.messages
  to authenticated, anon, service_role;

-- ── 8. Realtime ─────────────────────────────────────────────────────────────
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
-- Vérification rapide
-- =============================================================================
-- Doit retourner 3 tables : conversations, conversation_participants, messages
select table_name, column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name in ('conversations', 'conversation_participants', 'messages')
order by table_name, ordinal_position;

-- =============================================================================
-- Done. Le sous-système de messagerie est prêt.
-- =============================================================================
