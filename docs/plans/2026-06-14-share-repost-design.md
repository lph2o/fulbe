# Design — Partage de posts (DM + Repost)

**Date :** 2026-06-14
**Contexte :** Fulɓe Connect — fil d'actualité
**Inspiration :** Instagram (double mode de partage)

---

## Résumé

Actuellement, le `PostCard` possède un seul bouton de partage (✈️ `paperPlaneTilt`) qui déclenche la feuille de partage native de l'OS. On ajoute deux modes de partage distincts :

1. **✈️ Envoyer à un contact (DM)** — Bouton share existant, redirigé vers une bottom sheet listant les conversations récentes
2. **🔄 Reposter dans son fil** — Nouvelle icône `arrowsClockwise` qui ouvre un dialogue de confirmation avec commentaire optionnel

---

## Barre d'actions finale

```
❤️ Like    💬 Commentaires    🔄 Reposter    ✈️ Partager    🔖 Favori
```

---

## 1. Action ✈️ — Partager en DM (bottom sheet)

### Comportement

1. L'utilisateur appuie sur ✈️
2. Une **bottom sheet** « Envoyer à... » s'ouvre, affichant :
   - Barre de recherche de contacts
   - Liste des conversations récentes (directes + groupes)
3. L'utilisateur sélectionne une conversation
4. Un message spécial `msg_type: 'post_share'` est envoyé avec `post_id` dans `metadata`
5. Le message s'affiche comme une **carte miniature** du post partagé dans la conversation
6. Enregistre dans `post_shares` avec `share_type = 'dm'`

### UI

```
┌─────────────────────────────────────┐
│  ✕  Envoyer à...                    │
│  ┌──────────────────────────────┐   │
│  │ 🔍 Rechercher un contact...  │   │
│  └──────────────────────────────┘   │
│                                     │
│  👤 Amadou Diallo         📤      │
│  👤 Fatoumata Sow         📤      │
│  👥 Groupe Dakar          📤      │
│  ...                               │
└─────────────────────────────────────┘
```

---

## 2. Action 🔄 — Reposter dans son fil (dialogue)

### Comportement

1. L'utilisateur appuie sur 🔄
2. Un **dialogue de confirmation** s'affiche avec :
   - Champ texte optionnel pour un commentaire (max 300 car.)
   - Aperçu miniature du post original
   - Boutons « Annuler » / « Reposter »
3. Si confirmé, un **nouveau post** est créé dans `posts` avec `repost_of = post_id`
4. Le post s'affiche dans le feed avec une **carte embed** du post original
5. Enregistre dans `post_shares` avec `share_type = 'repost'`
6. L'icône 🔄 est **active/surlignée** si l'utilisateur a déjà reposté ce post

### UI

```
┌─────────────────────────────────────┐
│  🔄  Reposter ce post ?             │
│                                     │
│  ┌──────────────────────────────┐   │
│  │ Ajouter un commentaire...    │   │
│  │ (optionnel, max 300 car.)    │   │
│  └──────────────────────────────┘   │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  👤 Auteur   ·   ville, pays │   │
│  │  Texte du post original...   │   │
│  └──────────────────────────────┘   │
│                                     │
│         [Annuler]  [Reposter]       │
└─────────────────────────────────────┘
```

---

## 3. Rendu du repost dans le feed

Un post reposté (`repost_of != null`) affiche :

```
┌──────────────────────────────────────────┐
│  [Header reposteur]          🔄 Reposté  │
│  Commentaire du reposteur...             │
│  ┌────────────────────────────────────┐  │
│  │ 👤 Auteur original  ·  ville, pays│  │
│  │ Contenu du post original...        │  │
│  │ [Image si présente]                │  │
│  └────────────────────────────────────┘  │
│  ❤️  💬  🔄  ✈️               🔖  │
└──────────────────────────────────────────┘
```

---

## 4. Modèle de données

### Migration SQL

```sql
-- 1. Ajouter share_type à post_shares
ALTER TABLE public.post_shares
  ADD COLUMN IF NOT EXISTS share_type text DEFAULT 'native';
-- Valeurs : 'native' (OS share), 'dm' (message privé), 'repost' (fil)

-- 2. Ajouter repost_of à posts
ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS repost_of uuid REFERENCES public.posts(id) ON DELETE SET NULL;

-- 3. Ajouter metadata aux messages (pour post_share)
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;

-- 4. Index pour les reposts
CREATE INDEX IF NOT EXISTS idx_posts_repost_of ON public.posts(repost_of);

-- 5. Mettre à jour la vue v_home_feed pour inclure les infos du post original
DROP VIEW IF EXISTS public.v_home_feed;
CREATE VIEW public.v_home_feed
WITH (security_invoker = true) AS
SELECT
  p.id,
  p.author_id,
  p.content,
  p.image_url,
  p.likes_count,
  p.comments_count,
  p.shares_count,
  p.time_ago,
  p.created_at,
  p.updated_at,
  p.event_id,
  p.repost_of,
  m.full_name        AS author_name,
  m.city             AS author_city,
  m.country          AS author_country,
  m.avatar_url       AS author_avatar_url,
  m.initials         AS author_initials,
  m.is_verified      AS author_is_verified
FROM public.posts p
LEFT JOIN public.members m ON m.id = p.author_id
ORDER BY p.created_at desc;
```

### Modèle Dart `Post`

```dart
class Post {
  // ... champs existants ...
  
  /// ID du post original si c'est un repost (null sinon)
  final String? repostOf;
  
  /// Post original embed (chargé séparément pour les reposts)
  final Post? repostOriginal;
  
  /// Le membre courant a-t-il reposté ce post ?
  final bool isReposted;
}
```

---

## 5. Fichiers impactés

| Fichier | Nature du changement |
|---------|---------------------|
| `supabase/migrations/20260614_026_share_repost.sql` | **Nouveau** — Migration SQL |
| `lib/core/data/models/post.dart` | Ajout `repostOf`, `repostOriginal`, `isReposted` |
| `lib/core/data/repositories/posts_repository.dart` | Ajout `repost()`, `sendPostAsDM()`, modifier `recordShare()` |
| `lib/core/data/repositories/conversations_repository.dart` | Modifier `sendMessage()` pour accepter `metadata` |
| `lib/shared/widgets/post_card.dart` | Ajout icône repost, dialogue repost, nouvelle bottom sheet share |
| `lib/shared/widgets/share_sheet.dart` | **Nouveau** — Bottom sheet « Envoyer à... » |
| `lib/shared/widgets/repost_dialog.dart` | **Nouveau** — Dialogue de confirmation repost |
| `lib/features/messages/conversation_detail_screen.dart` | Rendu message `post_share` |
| `lib/core/data/providers/data_providers.dart` | Provider pour les posts repostés par l'utilisateur |

---

## 6. Points d'attention

- **Toggle repost** : Si l'utilisateur a déjà reposté, recliquer annule (supprime le post de repost)
- **Cascade delete** : Si le post original est supprimé, `repost_of` → NULL (pas de suppression en cascade des reposts)
- **Pagination** : La vue `v_home_feed` inclut les reposts comme des posts normaux
- **Notification** : (futur) Repost pourrait déclencher une notif à l'auteur original
