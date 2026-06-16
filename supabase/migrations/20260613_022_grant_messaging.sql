-- =============================================================================
-- Fulɓe Connect — Grant INSERT/UPDATE/DELETE on messaging tables
-- =============================================================================
-- Date    : 2026-06-13
-- Purpose : Les tables de messagerie (conversations, conversation_participants,
--           messages) ont été créées dans la migration 007, APRÈS le grant
--           global de 002_rls_policies.sql. Le grant "on all tables" étant
--           statique en Postgres, ces tables n'ont jamais reçu les privilèges
--           INSERT / UPDATE / DELETE pour le rôle authenticated.
--
--           Résultat : findOrCreateDirectConversation et sendMessage
--           échouaient silencieusement côté client (permission denied),
--           rendant impossible d'envoyer un message depuis un profil.
-- =============================================================================

grant select, insert, update, delete on
  public.conversations,
  public.conversation_participants,
  public.messages
  to authenticated;

-- =============================================================================
-- Done.
-- =============================================================================
