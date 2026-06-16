-- =============================================================================
-- Fulɓe Connect — Fix RLS infinite recursion on group_calls
-- =============================================================================
-- Date    : 2026-06-16
-- Issue   : group_calls_select queries group_call_participants, which triggers
--           group_call_participants_select, which queries group_calls back.
--           → Postgres 42P17 infinite recursion.
--
-- Fix     : Security definer functions bypass RLS and break the cycle.
--           The functions run with the owner's privileges (table owner = superuser
--           in local dev / dashboard user in production) so they can read the
--           tables without triggering RLS re-evaluation on the other table.
-- =============================================================================

-- ── Helper functions (security definer to bypass RLS recursion) ────────────

create or replace function public.is_group_call_participant(
  group_call_id uuid,
  member_id uuid
)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.group_call_participants
    where group_call_participants.group_call_id = $1
      and group_call_participants.member_id = $2
  );
$$;

comment on function public.is_group_call_participant is
  'Security-definer check whether a member is a participant of a group call. '
  'Bypasses RLS to avoid infinite recursion between group_calls and group_call_participants policies.';

create or replace function public.is_group_call_caller(
  group_call_id uuid,
  member_id uuid
)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.group_calls
    where group_calls.id = $1
      and group_calls.caller_id = $2
  );
$$;

comment on function public.is_group_call_caller is
  'Security-definer check whether a member is the caller of a group call. '
  'Bypasses RLS to avoid infinite recursion between group_calls and group_call_participants policies.';

-- ── Updated RLS policies using security-definer helpers ────────────────────

drop policy if exists "group_calls_select" on public.group_calls;
create policy "group_calls_select" on public.group_calls
  for select using (
    caller_id = (select id from public.members where user_id = auth.uid())
    or public.is_group_call_participant(
         id,
         (select id from public.members where user_id = auth.uid())
       )
  );

drop policy if exists "group_calls_update" on public.group_calls;
create policy "group_calls_update" on public.group_calls
  for update using (
    caller_id = (select id from public.members where user_id = auth.uid())
    or public.is_group_call_participant(
         id,
         (select id from public.members where user_id = auth.uid())
       )
  )
  with check (
    caller_id = (select id from public.members where user_id = auth.uid())
    or public.is_group_call_participant(
         id,
         (select id from public.members where user_id = auth.uid())
       )
  );

drop policy if exists "group_call_participants_select" on public.group_call_participants;
create policy "group_call_participants_select" on public.group_call_participants
  for select using (
    member_id = (select id from public.members where user_id = auth.uid())
    or public.is_group_call_caller(
         group_call_id,
         (select id from public.members where user_id = auth.uid())
       )
  );

drop policy if exists "group_call_participants_insert" on public.group_call_participants;
create policy "group_call_participants_insert" on public.group_call_participants
  for insert with check (
    member_id = (select id from public.members where user_id = auth.uid())
    or public.is_group_call_caller(
         group_call_id,
         (select id from public.members where user_id = auth.uid())
       )
  );

drop policy if exists "group_call_participants_update" on public.group_call_participants;
create policy "group_call_participants_update" on public.group_call_participants
  for update using (
    member_id = (select id from public.members where user_id = auth.uid())
    or public.is_group_call_caller(
         group_call_id,
         (select id from public.members where user_id = auth.uid())
       )
  )
  with check (
    member_id = (select id from public.members where user_id = auth.uid())
    or public.is_group_call_caller(
         group_call_id,
         (select id from public.members where user_id = auth.uid())
       )
  );

-- =============================================================================
-- Done.
-- =============================================================================
