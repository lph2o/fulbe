-- =============================================================================
-- Fulɓe Connect — Member Follows (follower / following relationships)
-- =============================================================================
-- Date    : 2026-06-11
-- Purpose : Allow members to follow/unfollow other members with server-side
--           persistence. Used by ProfileScreen to display real follower and
--           following counts instead of hardcoded mock values.
-- Order   : Run after 001_init_schema.sql (depends on members table)
--
-- Conventions follow post_likes (010) and comment_likes (012):
--   * schema-primary-keys          : UUID primary keys with gen_random_uuid()
--   * schema-foreign-key-indexes   : index on every FK column
--   * schema-constraints           : NOT NULL + UNIQUE(follower_id, following_id)
--   * security-rls-basics          : RLS enabled, self-insert / self-delete policies
-- =============================================================================

-- =============================================================================
-- 1. member_follows table
-- =============================================================================
create table if not exists public.member_follows (
  id            uuid        primary key default gen_random_uuid(),
  follower_id   uuid        not null references public.members(id) on delete cascade,
  following_id  uuid        not null references public.members(id) on delete cascade,
  created_at    timestamptz not null default now(),
  unique (follower_id, following_id)
);

create index if not exists idx_member_follows_follower_id  on public.member_follows(follower_id);
create index if not exists idx_member_follows_following_id on public.member_follows(following_id);

comment on table public.member_follows is
  'Follow relationships between members. follower_id follows following_id.';

-- =============================================================================
-- 2. RLS
-- =============================================================================
alter table public.member_follows enable row level security;

-- Anyone authenticated can read follows (needed to display counts)
drop policy if exists "member_follows_select_authenticated" on public.member_follows;
create policy "member_follows_select_authenticated"
  on public.member_follows for select
  using (true);

-- Authenticated users can follow (insert) — follower must be themselves
drop policy if exists "member_follows_insert_self" on public.member_follows;
create policy "member_follows_insert_self"
  on public.member_follows for insert
  with check (
    follower_id in (
      select m.id from public.members m
      where m.user_id = auth.uid()
    )
  );

-- Authenticated users can unfollow (delete) — can only delete their own follows
drop policy if exists "member_follows_delete_self" on public.member_follows;
create policy "member_follows_delete_self"
  on public.member_follows for delete
  using (
    follower_id in (
      select m.id from public.members m
      where m.user_id = auth.uid()
    )
  );

-- =============================================================================
-- 3. Grant permissions
-- =============================================================================
grant select, insert, delete on public.member_follows to authenticated;

-- =============================================================================
-- 4. Add to realtime publication (optional — for live follow count updates)
-- =============================================================================
alter publication supabase_realtime add table public.member_follows;

-- =============================================================================
-- 5. Seed data (dev only)
-- =============================================================================
do $$
declare
  -- Use existing seed member UUIDs from 003_seed_dev_data.sql
  member_aaliyah  uuid := 'a0000004-0000-0000-0000-000000000004';
  member_amadou   uuid := 'a0000001-0000-0000-0000-000000000001';
  member_aissatou uuid := 'a0000002-0000-0000-0000-000000000002';
  member_oussmane uuid := 'a0000003-0000-0000-0000-000000000003';
  member_fatou    uuid := 'a0000005-0000-0000-0000-000000000005';
  member_mariama  uuid := 'a0000006-0000-0000-0000-000000000006';
  member_djibril  uuid := 'a0000007-0000-0000-0000-000000000007';
  member_kadiatou uuid := 'a0000008-0000-0000-0000-000000000008';
begin
  -- Amadou follows: Aaliyah, Aissatou, Oussmane, Mariama (4 following)
  insert into public.member_follows (follower_id, following_id, created_at) values
    (member_amadou, member_aaliyah,  now() - interval '30 days'),
    (member_amadou, member_aissatou, now() - interval '25 days'),
    (member_amadou, member_oussmane, now() - interval '20 days'),
    (member_amadou, member_mariama,  now() - interval '15 days')
  on conflict do nothing;

  -- Aissatou follows: Amadou, Oussmane, Fatou, Aaliyah, Djibril (5 following)
  insert into public.member_follows (follower_id, following_id, created_at) values
    (member_aissatou, member_amadou,  now() - interval '28 days'),
    (member_aissatou, member_oussmane, now() - interval '22 days'),
    (member_aissatou, member_fatou,   now() - interval '18 days'),
    (member_aissatou, member_aaliyah, now() - interval '12 days'),
    (member_aissatou, member_djibril, now() - interval '5 days')
  on conflict do nothing;

  -- Oussmane follows: Amadou, Aissatou, Aaliyah (3 following)
  insert into public.member_follows (follower_id, following_id, created_at) values
    (member_oussmane, member_amadou,  now() - interval '20 days'),
    (member_oussmane, member_aissatou, now() - interval '18 days'),
    (member_oussmane, member_aaliyah, now() - interval '10 days')
  on conflict do nothing;

  -- Aaliyah's followers: Amadou, Aissatou, Oussmane, Fatou, Mariama, Kadiatou (6 followers)
  -- (already inserted above as following Aaliyah, plus extra)
  insert into public.member_follows (follower_id, following_id, created_at) values
    (member_fatou,   member_aaliyah, now() - interval '14 days'),
    (member_mariama, member_aaliyah, now() - interval '8 days'),
    (member_kadiatou, member_aaliyah, now() - interval '3 days')
  on conflict do nothing;

  -- Amadou's followers: Aissatou, Oussmane, Fatou, Djibril (4 followers)
  -- (Aissatou and Oussmane already inserted above as following Amadou)
  insert into public.member_follows (follower_id, following_id, created_at) values
    (member_fatou,   member_amadou, now() - interval '10 days'),
    (member_djibril, member_amadou, now() - interval '6 days')
  on conflict do nothing;
end $$;

-- =============================================================================
-- Done.
-- =============================================================================
