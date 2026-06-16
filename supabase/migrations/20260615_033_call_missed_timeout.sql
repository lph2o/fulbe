-- =============================================================================
-- Fulɓe Connect — Call Missed Timeout (30s)
-- =============================================================================
-- Date    : 2026-06-15
-- Purpose : Marque automatiquement les appels sans réponse comme 'missed' après
--           30 secondes et insère un message système dans la conversation.
-- Order   : Après 20260615_032_group_calls.sql
--
-- Design  :
--   - Fonction `mark_stale_calls_missed()` : boucle sur les call_invites
--     et group_calls en statut 'pending' depuis > 30s, les passe à
--     'missed' / 'cancelled', et insère un message dans `messages`.
--   - Optionnel : si pg_cron est disponible, un job exécute la fonction
--     toutes les 5 secondes. Sinon, la fonction peut être appelée
--     manuellement ou via une Edge Function planifiée.
-- =============================================================================

-- ── 1. Fonction de nettoyage des appels expirés ────────────────────────────

CREATE OR REPLACE FUNCTION public.mark_stale_calls_missed()
RETURNS integer AS $$
DECLARE
  stale_1to1 RECORD;
  stale_group RECORD;
  total_count integer := 0;
BEGIN
  -- ── 1-to-1 calls (call_invites) ──────────────────────────────────────────
  FOR stale_1to1 IN
    SELECT
      ci.id,
      ci.caller_id,
      ci.callee_id,
      ci.conversation_id,
      ci.call_type
    FROM public.call_invites ci
    WHERE ci.status = 'pending'
      AND ci.created_at < (now() - interval '30 seconds')
  LOOP
    -- Marque comme manqué (re-check status pour éviter une race condition
    -- si l'appelé accepte entre le SELECT et le UPDATE).
    UPDATE public.call_invites
    SET status = 'missed',
        ended_at = now()
    WHERE id = stale_1to1.id
      AND status = 'pending';

    -- Si le statut a changé entre-temps, on ne fait rien
    IF NOT FOUND THEN
      CONTINUE;
    END IF;

    -- Insère un message système dans la conversation
    INSERT INTO public.messages (
      conversation_id,
      sender_id,
      content,
      metadata
    ) VALUES (
      stale_1to1.conversation_id,
      stale_1to1.caller_id,
      '',
      jsonb_build_object(
        'msg_type', 'call',
        'call_type', stale_1to1.call_type,
        'call_status', 'missed',
        'caller_id', stale_1to1.caller_id,
        'callee_id', stale_1to1.callee_id
      )
    );

    total_count := total_count + 1;
  END LOOP;

  -- ── Group calls ──────────────────────────────────────────────────────────
  FOR stale_group IN
    SELECT
      gc.id,
      gc.caller_id,
      gc.conversation_id,
      gc.call_type
    FROM public.group_calls gc
    WHERE gc.status = 'pending'
      AND gc.created_at < (now() - interval '30 seconds')
  LOOP
    -- Marque comme annulé (timeout), avec re-check du statut
    UPDATE public.group_calls
    SET status = 'cancelled',
        ended_at = now()
    WHERE id = stale_group.id
      AND status = 'pending';

    -- Si le statut a changé entre-temps, on ne fait rien
    IF NOT FOUND THEN
      CONTINUE;
    END IF;

    -- Insère un message système dans la conversation
    INSERT INTO public.messages (
      conversation_id,
      sender_id,
      content,
      metadata
    ) VALUES (
      stale_group.conversation_id,
      stale_group.caller_id,
      '',
      jsonb_build_object(
        'msg_type', 'call',
        'call_type', stale_group.call_type,
        'call_status', 'cancelled',
        'caller_id', stale_group.caller_id,
        'is_group', true
      )
    );

    total_count := total_count + 1;
  END LOOP;

  RETURN total_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

COMMENT ON FUNCTION public.mark_stale_calls_missed() IS
  'Marque les appels (1-to-1 et groupe) en statut pending depuis > 30s comme missed/cancelled et insère un message système. Retourne le nombre d''appels traités.';

-- ── 2. Planification avec pg_cron (si disponible) ─────────────────────────
-- Exécute la fonction toutes les 5 secondes pour une réactivité acceptable.
-- Si pg_cron n'est pas installé, ce bloc est ignoré silencieusement.

DO $$
BEGIN
  -- Vérifie que l'extension pg_cron est disponible
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) THEN
    -- Supprime l'ancien job s'il existe (idempotent)
    PERFORM cron.unschedule('mark_stale_calls_missed_job');

    -- Planifie le job : toutes les 5 secondes
    PERFORM cron.schedule(
      'mark_stale_calls_missed_job',
      '5 seconds',
      'SELECT public.mark_stale_calls_missed();'
    );
  END IF;
END $$;

-- =============================================================================
-- Instructions si pg_cron n'est pas disponible
-- =============================================================================
-- Si votre plan Supabase ne supporte pas pg_cron, vous avez 2 alternatives :
--
-- A) Edge Function planifiée (recommandé) :
--    Créez une Edge Function Supabase qui appelle `mark_stale_calls_missed()`
--    et planifiez-la avec un cron job externe ou Supabase Scheduled Functions.
--
--    Exemple (Deno) :
--    ```ts
--    import { serve } from 'https://deno.land/std/http/server.ts';
--    import { createClient } from 'https://esm.sh/@supabase/supabase-js';
--
--    serve(async () => {
--      const supabase = createClient(
--        Deno.env.get('SUPABASE_URL')!,
--        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
--      );
--      const { data } = await supabase.rpc('mark_stale_calls_missed');
--      return new Response(JSON.stringify({ marked: data }), { status: 200 });
--    });
--    ```
--
-- B) Appel manuel périodique depuis le client :
--    Appelez `supabase.rpc('mark_stale_calls_missed')` périodiquement
--    (ex: dans un Timer toutes les 10 secondes côté Flutter).
--
-- =============================================================================
-- Done.
-- =============================================================================
