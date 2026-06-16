-- =============================================================================
-- Fulɓe Connect — Fix RLS SELECT policy pour les conversations fraîchement créées
-- =============================================================================
-- Date    : 2026-06-14
-- Problem : INSERT INTO conversations AVEC .select('id') échoue (RLS 42501)
--           car la policy conv_select_participant vérifie is_participant(),
--           qui retourne FALSE avant l'insertion des conversation_participants.
-- Fix     : Autoriser la lecture d'une conversation qui n'a pas encore de
--           participants (état transitoire entre l'insertion de la conversation
--           et celle de ses participants).
-- Usage   : Copier-coller dans le SQL Editor de Supabase → RUN.
-- ⚠️       CE SCRIPT NE SUPPRIME AUCUNE DONNÉE. Modifie UNE SEULE policy.
-- =============================================================================

drop policy if exists "conv_select_participant" on public.conversations;

create policy "conv_select_participant" on public.conversations
  for select using (
    public.is_participant(id, auth.uid())
    or not exists (
      -- Conversation sans participants = vient d'être créée, pas encore peuplée
      select 1 from public.conversation_participants cp
      where cp.conversation_id = id
    )
  );
