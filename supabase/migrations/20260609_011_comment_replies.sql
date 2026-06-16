-- =============================================================================
-- Fulɓe Connect — Comment Replies (threaded comments)
-- =============================================================================
-- Date    : 2026-06-11
-- Purpose : Allow users to reply to other comments, creating a simple
--           one-level-deep threaded conversation structure.
-- Order   : Run after 009_post_comments.sql
-- =============================================================================

-- =============================================================================
-- 1. Add parent_comment_id to post_comments
-- =============================================================================
alter table public.post_comments
  add column if not exists parent_comment_id uuid
  references public.post_comments(id) on delete cascade;

create index if not exists idx_post_comments_parent_id
  on public.post_comments(parent_comment_id);

-- =============================================================================
-- 2. Update view v_post_comments to include parent info
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
