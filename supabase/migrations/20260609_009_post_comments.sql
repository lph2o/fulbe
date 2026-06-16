-- =============================================================================
-- Fulɓe Connect — Post Comments
-- =============================================================================
-- Date    : 2026-06-11
-- Purpose : Allow users to comment on posts in the home feed.
-- Order   : Run after 004_functions_triggers.sql (depends on tg_set_updated_at)
--
-- Best practices applied:
--   * schema-primary-keys          : UUID primary keys with gen_random_uuid()
--   * schema-foreign-key-indexes   : index on every FK column
--   * schema-constraints           : NOT NULL + CHECK (content not empty)
--   * data-batch-inserts           : single INSERT ... VALUES
-- =============================================================================

-- =============================================================================
-- 1. post_comments table
-- =============================================================================
create table if not exists public.post_comments (
  id         uuid        primary key default gen_random_uuid(),
  post_id    uuid        not null references public.posts(id) on delete cascade,
  author_id  uuid        not null references public.members(id) on delete cascade,
  content    text        not null check (char_length(content) > 0),
  created_at timestamptz not null default now()
);

create index if not exists idx_post_comments_post_id   on public.post_comments(post_id);
create index if not exists idx_post_comments_author_id on public.post_comments(author_id);
create index if not exists idx_post_comments_created_at on public.post_comments(created_at desc);

-- =============================================================================
-- 2. RLS
-- =============================================================================
alter table public.post_comments enable row level security;

-- Anyone authenticated can read comments
drop policy if exists "post_comments_select_authenticated" on public.post_comments;
create policy "post_comments_select_authenticated"
  on public.post_comments for select
  using (true);

-- Authenticated users can insert their own comments
drop policy if exists "post_comments_insert_self" on public.post_comments;
create policy "post_comments_insert_self"
  on public.post_comments for insert
  with check (
    author_id in (
      select m.id from public.members m
      where m.user_id = auth.uid()
    )
  );

-- =============================================================================
-- 3. Trigger: auto-update posts.comments_count
-- =============================================================================
create or replace function public.tg_post_comment_count()
returns trigger
language plpgsql
as $$
begin
  if (tg_op = 'INSERT') then
    update public.posts
       set comments_count = comments_count + 1
     where id = new.post_id;
    return new;
  elsif (tg_op = 'DELETE') then
    update public.posts
       set comments_count = greatest(0, comments_count - 1)
     where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_post_comment_count_insert on public.post_comments;
create trigger trg_post_comment_count_insert
  after insert on public.post_comments
  for each row execute function public.tg_post_comment_count();

drop trigger if exists trg_post_comment_count_delete on public.post_comments;
create trigger trg_post_comment_count_delete
  after delete on public.post_comments
  for each row execute function public.tg_post_comment_count();

-- =============================================================================
-- 4. Add to realtime publication
-- =============================================================================
alter publication supabase_realtime add table public.post_comments;

-- =============================================================================
-- 5. Seed data (dev only)
-- =============================================================================
-- Uses the deterministic UUIDs from 003_seed_dev_data.sql.
do $$
declare
  member_mariama uuid := 'a0000006-0000-0000-0000-000000000006';
  member_fatou   uuid := 'a0000004-0000-0000-0000-000000000004';
  member_amadou  uuid := 'a0000001-0000-0000-0000-000000000001';
  post_mariama   uuid := 'c0000001-0000-0000-0000-000000000001';
  post_fatou     uuid := 'c0000002-0000-0000-0000-000000000002';
  post_aissatou  uuid := 'c0000003-0000-0000-0000-000000000003';
begin
  insert into public.post_comments (post_id, author_id, content, created_at) values
    (post_mariama, member_fatou,  'Magnifique travail ! Les motifs géométriques sont incroyables. 👏', now() - interval '1 hour'),
    (post_mariama, member_amadou, 'Félicitations Mariama ! Un bel exemple de fusion culturelle.', now() - interval '45 minutes'),
    (post_fatou,   member_amadou,  'Très inspirant ! Hâte de voir la suite du projet. 🚀', now() - interval '3 hours'),
    (post_fatou,   member_mariama, 'Merci pour ce partage ! La diaspora tech a un bel avenir.', now() - interval '2 hours'),
    (post_aissatou, member_fatou,  'Sujet crucial. Bravo pour ce travail de sensibilisation !', now() - interval '20 hours')
  on conflict do nothing;
end $$;

-- =============================================================================
-- 6. View: v_post_comments (flattened with author info)
-- =============================================================================
create or replace view public.v_post_comments
with (security_invoker = true) as
select
  pc.id,
  pc.post_id,
  pc.author_id,
  pc.content,
  pc.created_at,
  m.full_name   as author_name,
  m.avatar_url  as author_avatar_url,
  m.initials    as author_initials
from public.post_comments pc
left join public.members m on m.id = pc.author_id
order by pc.created_at asc;

comment on view public.v_post_comments is
  'Post comments with author info denormalized. Ordered oldest first.';

grant select on public.v_post_comments to authenticated;

-- =============================================================================
-- Done.
-- =============================================================================
