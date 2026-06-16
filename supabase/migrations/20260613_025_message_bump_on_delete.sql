-- =============================================================================
-- Fulɓe Connect — Étendre tg_message_bump_conversation pour les DELETE
-- =============================================================================
-- Date    : 2026-06-13
-- Purpose : La fonction tg_message_bump_conversation (migration 023) ne gérait
--           que INSERT. On l'étend pour supporter aussi DELETE (via old),
--           et on ajoute un trigger AFTER DELETE sur messages.
--           Ainsi, si la suppression de messages est implémentée plus tard,
--           conversations.updated_at restera cohérent sans migration
--           supplémentaire.
-- =============================================================================

create or replace function public.tg_message_bump_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  _conv_id uuid;
begin
  -- Détermine l'ID de la conversation selon l'opération.
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

drop trigger if exists trg_message_bump_conversation_delete on public.messages;
create trigger trg_message_bump_conversation_delete
  after delete on public.messages
  for each row execute function public.tg_message_bump_conversation();

-- =============================================================================
-- Done.
-- =============================================================================
