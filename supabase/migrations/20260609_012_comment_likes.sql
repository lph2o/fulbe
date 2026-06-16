-- =============================================================================
-- Fulɓe Connect — Comment Likes
-- =============================================================================
-- Date    : 2026-06-11
-- Purpose : Allow users to like/unlike individual comments with server-side
--           persistence and auto-maintained likes_count on post_comments.
-- Order   : Run after 011_comment_replies.sql
-- =============================================================================

-- =============================================================================
-- 1. Add likes_count column to post_comments
-- =============================================================================
alter table public.post_comments
  add column if not exists likes_count integer not null default 0;

-- =============================================================================
-- 2. comment_likes table
-- =============================================================================
create table if not exists public.comment_likes (
  id            uuid        primary key default gen_random_uuid(),
  comment_id    uuid        not null references public.post_comments(id) on delete cascade,
  user_id       uuid        not null references public.members(id) on delete cascade,
  created_at    timestamptz not null default now(),
  unique (comment_id, user_id)
);

create index if not exists idx_comment_likes_comment_id on public.comment_likes(comment_id);
create index if not exists idx_comment_likes_user_id    on public.comment_likes(user_id);

-- =============================================================================
-- 3. RLS
-- =============================================================================
alter table public.comment_likes enable row level security;

drop policy if exists "comment_likes_select_authenticated" on public.comment_likes;
create policy "comment_likes_select_authenticated"
  on public.comment_likes for select
  using (true);

drop policy if exists "comment_likes_insert_self" on public.comment_likes;
create policy "comment_likes_insert_self"
  on public.comment_likes for insert
  with check (
    user_id in (
      select m.id from public.members m
      where m.user_id = auth.uid()
    )
  );

drop policy if exists "comment_likes_delete_self" on public.comment_likes;
create policy "comment_likes_delete_self"
  on public.comment_likes for delete
  using (
    user_id in (
      select m.id from public.members m
      where m.user_id = auth.uid()
    )
  );

-- =============================================================================
-- 4. Trigger: auto-update post_comments.likes_count
-- =============================================================================
create or replace function public.tg_comment_like_count()
returns trigger
language plpgsql
as $$
begin
  if (tg_op = 'INSERT') then
    update public.post_comments
       set likes_count = likes_count + 1
     where id = new.comment_id;
    return new;
  elsif (tg_op = 'DELETE') then
    update public.post_comments
       set likes_count = greatest(0, likes_count - 1)
     where id = old.comment_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_comment_like_count_insert on public.comment_likes;
create trigger trg_comment_like_count_insert
  after insert on public.comment_likes
  for each row execute function public.tg_comment_like_count();

drop trigger if exists trg_comment_like_count_delete on public.comment_likes;
create trigger trg_comment_like_count_delete
  after delete on public.comment_likes
  for each row execute function public.tg_comment_like_count();

-- =============================================================================
-- 5. Grant permissions
-- =============================================================================
grant select, insert, delete on public.comment_likes to authenticated;

-- =============================================================================
-- 6. Add to realtime publication
-- =============================================================================
alter publication supabase_realtime add table public.comment_likes;

-- =============================================================================
-- 7. Update v_post_comments to include likes_count
-- =============================================================================
-- On DROP d'abord car CREATE OR REPLACE ne peut pas changer l'ordre des colonnes.
drop view if exists public.v_post_comments;

create view public.v_post_comments
with (security_invoker = true) as
select
  pc.id,
  pc.post_id,
  pc.author_id,
  pc.parent_comment_id,
  pc.content,
  pc.created_at,
  pc.likes_count,
  m.full_name   as author_name,
  m.avatar_url  as author_avatar_url,
  m.initials    as author_initials
from public.post_comments pc
left join public.members m on m.id = pc.author_id
order by pc.created_at asc;

comment on view public.v_post_comments is
  'Post comments with author info and likes_count. Ordered oldest first.';

grant select on public.v_post_comments to authenticated;

-- =============================================================================
-- Done.
-- =============================================================================
