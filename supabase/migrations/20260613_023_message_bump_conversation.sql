-- =============================================================================
-- Fulɓe Connect — Trigger : bump conversations.updated_at on new message
-- =============================================================================
-- Date    : 2026-06-13
-- Purpose : Quand un nouveau message est inséré dans `messages`, mettre à jour
--           `conversations.updated_at` pour que la conversation remonte en haut
--           de la liste côté client (tri par updated_at DESC dans fetchAll).
--
--           La fonction est `security definer` pour court-circuiter les RLS
--           policies de la table `conversations` — seul le trigger (qui tourne
--           avec les privilèges du owner) a besoin d'écrire dans updated_at.
-- =============================================================================

create or replace function public.tg_message_bump_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations
     set updated_at = now()
   where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists trg_message_bump_conversation on public.messages;
create trigger trg_message_bump_conversation
  after insert on public.messages
  for each row execute function public.tg_message_bump_conversation();

-- =============================================================================
-- Done.
-- =============================================================================
