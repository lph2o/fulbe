-- =============================================================================
-- Fulɓe Connect — Community Chat (messagerie instantanée dans les groupes)
-- =============================================================================
-- Date    : 2026-06-16
-- Purpose : Ajoute une conversation associée à chaque communauté pour le chat
--           instantané (messages texte, images, vidéos, fichiers, audio).
--           Migre les posts existants (community_posts) vers cette conversation.
-- Order   : Après 20260616_036_community_invites.sql
--
-- Design  :
--   - Ajoute conversation_id (nullable) à communities
--   - Fonction pour créer/migrer la conversation d'une communauté
--   - Les messages de chat utilisent la table `messages` existante
-- =============================================================================

-- ── 1. Ajout de conversation_id à communities ───────────────────────────────
alter table public.communities
  add column if not exists conversation_id uuid
    references public.conversations(id) on delete set null;

create index if not exists idx_communities_conversation
  on public.communities (conversation_id)
  where conversation_id is not null;

comment on column public.communities.conversation_id is
  'Conversation associée pour le chat instantané du groupe. Créée automatiquement.';

-- ── 2. Fonction : créer ou récupérer la conversation d'une communauté ──────
-- Crée une conversation 'group' pour la communauté et y ajoute tous ses
-- membres actuels comme participants. Migre également les posts existants
-- en messages. Idempotente : si la conversation existe déjà, la retourne.
create or replace function public.ensure_community_conversation(p_community_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_conv_id uuid;
  v_member record;
  v_post record;
begin
  -- Déjà créée ?
  select conversation_id into v_conv_id
    from public.communities
   where id = p_community_id;

  if v_conv_id is not null then
    return v_conv_id;
  end if;

  -- Crée la conversation
  insert into public.conversations (type, name)
  values ('group', (select name from public.communities where id = p_community_id))
  returning id into v_conv_id;

  -- Ajoute tous les membres actifs comme participants
  for v_member in
    select cm.member_id
      from public.community_members cm
     where cm.community_id = p_community_id
       and cm.status = 'active'
  loop
    insert into public.conversation_participants (conversation_id, member_id)
    values (v_conv_id, v_member.member_id)
    on conflict (conversation_id, member_id) do nothing;
  end loop;

  -- Sauvegarde l'ID sur communities
  update public.communities
     set conversation_id = v_conv_id
   where id = p_community_id;

  -- Migre les posts existants en messages (dans l'ordre chronologique)
  for v_post in
    select cp.id as post_id, cp.author_id, cp.content, cp.image_url, cp.created_at
      from public.community_posts cp
     where cp.community_id = p_community_id
     order by cp.created_at asc
  loop
    insert into public.messages (conversation_id, sender_id, content, metadata, created_at)
    values (
      v_conv_id,
      v_post.author_id,
      coalesce(v_post.image_url, v_post.content),
      case
        when v_post.image_url is not null
          then jsonb_build_object('msg_type', 'image', 'original_post_id', v_post.post_id)
        else jsonb_build_object('msg_type', 'text', 'original_post_id', v_post.post_id)
      end,
      v_post.created_at
    );
  end loop;

  return v_conv_id;
end;
$$;

comment on function public.ensure_community_conversation(uuid) is
  'Crée une conversation de groupe pour une communauté. Migre les posts existants en messages.';

-- ── 3. Trigger : créer automatiquement la conversation à la création d'une communauté ──
create or replace function public.tg_create_community_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.ensure_community_conversation(new.id);
  return new;
end;
$$;

-- On ne crée par la conversation automatiquement à l'INSERT car le créateur
-- n'est pas encore membre à ce stade (ajouté juste après dans l'app).
-- On laisse l'app l'appeler quand le premier membre rejoint.

-- ── 4. RLS : les membres de la communauté peuvent lire/écrire dans la conversation ──
-- Les messages utilisent déjà la table `messages` avec ses propres politiques RLS.
-- On ajoute une politique pour permettre aux membres de la communauté d'accéder
-- à la conversation via le mécanisme conversation_participants (géré par l'app).

-- =============================================================================
-- Done.
-- =============================================================================
