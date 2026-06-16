-- =============================================================================
-- Fulɓe Connect — Trigger : auto-maintain posts.likes_count from post_likes
-- =============================================================================
-- Date    : 2026-06-13
-- Purpose : Quand un like est ajouté (INSERT) ou retiré (DELETE) dans
--           `post_likes`, incrémenter/décrémenter `posts.likes_count`
--           automatiquement. Supprime le besoin de compter côté client
--           et garantit l'intégrité du compteur même en cas de race condition.
--
--           Même pattern que tg_event_rsvp_count (migration 004) et
--           tg_message_bump_conversation (migration 023).
-- =============================================================================

create or replace function public.tg_post_like_count()
returns trigger
language plpgsql
security definer
set search_path = public
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
-- Done.
-- =============================================================================
