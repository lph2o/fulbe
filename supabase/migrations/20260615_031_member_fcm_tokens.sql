-- ──────────────────────────────────────────────────────────────────────────────
-- Migration : 2026-06-15-031 — Stockage des tokens FCM pour les notifications push
-- ──────────────────────────────────────────────────────────────────────────────

-- Table des tokens FCM (un membre peut avoir plusieurs appareils).
CREATE TABLE IF NOT EXISTS public.member_fcm_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id   UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  token       TEXT NOT NULL,
  platform    TEXT NOT NULL DEFAULT 'unknown', -- android, ios, macos, web, unknown
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Un token est unique par membre (multi-device autorisé via plusieurs lignes)
  UNIQUE(token)
);

-- Index pour retrouver rapidement les tokens d'un membre.
CREATE INDEX IF NOT EXISTS idx_member_fcm_tokens_member_id
  ON public.member_fcm_tokens(member_id);

COMMENT ON TABLE public.member_fcm_tokens IS
  'Tokens FCM/APNs des appareils par membre, utilisés pour les notifications push d''appels.';

-- RLS : chacun ne voit que ses propres tokens.
ALTER TABLE public.member_fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY member_fcm_tokens_select_own ON public.member_fcm_tokens
  FOR SELECT USING (member_id = auth.uid());

CREATE POLICY member_fcm_tokens_insert_own ON public.member_fcm_tokens
  FOR INSERT WITH CHECK (member_id = auth.uid());

CREATE POLICY member_fcm_tokens_update_own ON public.member_fcm_tokens
  FOR UPDATE USING (member_id = auth.uid());

CREATE POLICY member_fcm_tokens_delete_own ON public.member_fcm_tokens
  FOR DELETE USING (member_id = auth.uid());

-- Edge Function : envoyer une notification FCM à un membre.
-- Cette fonction est appelée par un trigger sur call_invites quand status = 'pending'.
CREATE OR REPLACE FUNCTION public.notify_call_invite()
RETURNS TRIGGER AS $$
BEGIN
  -- Sélectionne les tokens FCM du callee (appelé)
  -- NOTE : utilise l'API Legacy FCM (server key) car le trigger SQL ne peut pas générer de JWT OAuth2.
  -- Pour une migration vers FCM v1, remplacez ceci par un appel à une Edge Function.
  PERFORM
    net.http_post(
      url := 'https://fcm.googleapis.com/fcm/send',
      headers := jsonb_build_object(
        'Authorization', 'key=' || current_setting('app.fcm_server_key', true),
        'Content-Type', 'application/json'
      ),
      body := jsonb_build_object(
        'to', t.token,
        'priority', 'high',
        'notification', jsonb_build_object(
          'title', CASE WHEN NEW.call_type = 'video' THEN '📹 Appel vidéo entrant' ELSE '📞 Appel entrant' END,
          'body', (SELECT full_name FROM public.members WHERE id = NEW.caller_id) || ' vous appelle',
          'sound', 'default'
        ),
        'data', jsonb_build_object(
          'type', 'call',
          'call_invite_id', NEW.id,
          'caller_id', NEW.caller_id,
          'callee_id', NEW.callee_id,
          'conversation_id', NEW.conversation_id,
          'call_type', NEW.call_type,
          'channel_name', NEW.agora_channel,
          'caller_name', (SELECT full_name FROM public.members WHERE id = NEW.caller_id)
        )
      )
    )
  FROM public.member_fcm_tokens t
  WHERE t.member_id = NEW.callee_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger sur call_invites pour notifier le callee quand l'appel est pending.
DROP TRIGGER IF EXISTS trg_notify_call_invite ON public.call_invites;
CREATE TRIGGER trg_notify_call_invite
  AFTER INSERT ON public.call_invites
  FOR EACH ROW
  WHEN (NEW.status = 'pending')
  EXECUTE FUNCTION public.notify_call_invite();
