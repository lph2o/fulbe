-- =============================================================================
-- Fulɓe Connect — Fix RLS policies for messaging (minimal, no data loss)
-- =============================================================================
-- Date    : 2026-06-14
-- Problem : INSERT into conversations/conversation_participants fails with
--           "new row violates row-level security policy" (code 42501).
-- Cause 1 : `auth.role() = 'authenticated'` ne matche pas dans certains
--           environnements Supabase → remplacé par `auth.uid() IS NOT NULL`.
-- Cause 2 : `.insert().select('id')` déclenche la policy SELECT, qui échoue
--           car les conversation_participants ne sont pas encore insérés.
-- Usage   : Copier-coller dans le SQL Editor de Supabase → RUN.
-- ⚠️       CE SCRIPT NE SUPPRIME AUCUNE DONNÉE. Il ne fait que remplacer
--           les policies par des versions corrigées.
-- =============================================================================

-- ── conversations : INSERT ───────────────────────────────────────────────────
drop policy if exists "conv_insert_authenticated" on public.conversations;
create policy "conv_insert_authenticated" on public.conversations
  for insert with check (auth.uid() is not null);

-- ── conversations : SELECT (autorise les conversations sans participants) ────
drop policy if exists "conv_select_participant" on public.conversations;
create policy "conv_select_participant" on public.conversations
  for select using (
    public.is_participant(id, auth.uid())
    or not exists (
      select 1 from public.conversation_participants cp
      where cp.conversation_id = id
    )
  );

-- ── conversation_participants : INSERT ──────────────────────────────────────
drop policy if exists "cp_insert_self" on public.conversation_participants;
create policy "cp_insert_self" on public.conversation_participants
  for insert with check (auth.uid() is not null);

-- ── messages : INSERT ────────────────────────────────────────────────────────
drop policy if exists "msg_insert_participant" on public.messages;
create policy "msg_insert_participant" on public.messages
  for insert with check (
    public.is_participant(conversation_id, auth.uid())
    and exists (
      select 1 from public.members m
      where m.id = sender_id and m.user_id = auth.uid()
    )
  );

-- =============================================================================
-- Vérification rapide : liste les policies actives sur les 3 tables
-- =============================================================================
select
  schemaname,
  tablename,
  policyname,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('conversations', 'conversation_participants', 'messages')
order by tablename, cmd;
