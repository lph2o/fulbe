-- =============================================================================
-- Fulɓe Connect — Post Likes (server-side persisted likes)
-- =============================================================================
-- Date    : 2026-06-11
-- Purpose : Allow users to like/unlike posts with server-side persistence
--           and auto-maintained likes_count on the posts table.
-- Order   : Run after 004_functions_triggers.sql (depends on tg_set_updated_at)
--
-- Best practices applied:
--   * schema-primary-keys          : UUID primary keys with gen_random_uuid()
--   * schema-foreign-key-indexes   : index on every FK column
--   * schema-constraints           : NOT NULL + UNIQUE(post_id, user_id)
--   * security-rls-basics          : RLS enabled, policies for self only
--   * data-batch-inserts           : single INSERT ... VALUES
-- =============================================================================

-- =============================================================================
-- 1. post_likes table
-- =============================================================================
create table if not exists public.post_likes (
  id         uuid        primary key default gen_random_uuid(),
  post_id    uuid        not null references public.posts(id) on delete cascade,
  user_id    uuid        not null references public.members(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

create index if not exists idx_post_likes_post_id  on public.post_likes(post_id);
create index if not exists idx_post_likes_user_id  on public.post_likes(user_id);

-- =============================================================================
-- 2. RLS
-- =============================================================================
alter table public.post_likes enable row level security;

-- Anyone authenticated can read likes
drop policy if exists "post_likes_select_authenticated" on public.post_likes;
create policy "post_likes_select_authenticated"
  on public.post_likes for select
  using (true);

-- Authenticated users can insert their own likes
drop policy if exists "post_likes_insert_self" on public.post_likes;
create policy "post_likes_insert_self"
  on public.post_likes for insert
  with check (
    user_id in (
      select m.id from public.members m
      where m.user_id = auth.uid()
    )
  );

-- Authenticated users can delete their own likes
drop policy if exists "post_likes_delete_self" on public.post_likes;
create policy "post_likes_delete_self"
  on public.post_likes for delete
  using (
    user_id in (
      select m.id from public.members m
      where m.user_id = auth.uid()
    )
  );

-- =============================================================================
-- 3. Trigger: auto-update posts.likes_count
-- =============================================================================
create or replace function public.tg_post_like_count()
returns trigger
language plpgsql
as $$
begin
  if (tg_op = 'INSERT') then
    update public.posts
       set likes_count = likes_count + 1
     where id = new.post_id;
    return new;
  elsif (tg_op = 'DELETE') then
    update public.posts
       set likes_count = greatest(0, likes_count - 1)
     where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_post_like_count_insert on public.post_likes;
create trigger trg_post_like_count_insert
  after insert on public.post_likes
  for each row execute function public.tg_post_like_count();

drop trigger if exists trg_post_like_count_delete on public.post_likes;
create trigger trg_post_like_count_delete
  after delete on public.post_likes
  for each row execute function public.tg_post_like_count();

-- =============================================================================
-- 4. Grant permissions
-- =============================================================================
grant select, insert, delete on public.post_likes to authenticated;

-- =============================================================================
-- 5. Add to realtime publication
-- =============================================================================
alter publication supabase_realtime add table public.post_likes;

-- =============================================================================
-- 6. Seed data (dev only)
-- =============================================================================
do $$
declare
  member_amadou  uuid := 'a0000001-0000-0000-0000-000000000001';
  member_aissatou uuid := 'a0000002-0000-0000-0000-000000000002';
  member_oussmane uuid := 'a0000003-0000-0000-0000-000000000003';
  member_fatou   uuid := 'a0000004-0000-0000-0000-000000000004';
  member_mariama uuid := 'a0000006-0000-0000-0000-000000000006';
  post_mariama   uuid := 'c0000001-0000-0000-0000-000000000001';
  post_fatou     uuid := 'c0000002-0000-0000-0000-000000000002';
  post_aissatou  uuid := 'c0000003-0000-0000-0000-000000000003';
begin
  -- Mariama's post: liked by Fatou, Oussmane, Aissatou
  insert into public.post_likes (post_id, user_id, created_at) values
    (post_mariama, member_fatou,    now() - interval '2 days'),
    (post_mariama, member_oussmane, now() - interval '1 day'),
    (post_mariama, member_aissatou, now() - interval '12 hours')
  on conflict do nothing;

  -- Fatou's post: liked by Amadou, Mariama
  insert into public.post_likes (post_id, user_id, created_at) values
    (post_fatou, member_amadou, now() - interval '3 days'),
    (post_fatou, member_mariama, now() - interval '2 days')
  on conflict do nothing;

  -- Update likes_count to match seed data (3 + 2 = 5)
  update public.posts set likes_count = 3 where id = post_mariama;
  update public.posts set likes_count = 2 where id = post_fatou;
end $$;

-- =============================================================================
-- Done.
-- =============================================================================
