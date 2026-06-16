# Groupes / Communautés — Design Document

**Date** : 2026-06-16  
**Statut** : Validé ✅  
**Auteur** : Buffy (Codebuff AI)

---

## 1. Objectif

Permettre aux membres Fulɓe Connect de créer et rejoindre des **groupes/communautés** par centres d'intérêt, projets, ou régions — avec un feed de publications, des rôles membres, et une visibilité publique/privée.

---

## 2. Schéma Base de Données

### Table `communities`

```sql
create table if not exists public.communities (
  id              uuid        primary key default gen_random_uuid(),
  name            text        not null,
  description     text        not null default '',
  cover_url       text,
  category        text        not null,
  visibility      text        not null default 'public'
                              check (visibility in ('public', 'private')),
  member_count    integer     not null default 0,
  created_by      uuid        not null references public.members(id) on delete cascade,
  organization_id uuid        references public.organizations(id) on delete set null,
  chapter_id      uuid        references public.chapters(id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
```

Indexes, RLS et triggers `updated_at` standard.

### Table `community_members`

```sql
create table if not exists public.community_members (
  id            uuid        primary key default gen_random_uuid(),
  community_id  uuid        not null references public.communities(id) on delete cascade,
  member_id     uuid        not null references public.members(id) on delete cascade,
  role          text        not null default 'member'
                            check (role in ('admin', 'moderator', 'member')),
  status        text        not null default 'active'
                            check (status in ('active', 'pending')),
  joined_at     timestamptz not null default now(),
  unique (community_id, member_id)
);
```

### Table `community_posts`

```sql
create table if not exists public.community_posts (
  id            uuid        primary key default gen_random_uuid(),
  community_id  uuid        not null references public.communities(id) on delete cascade,
  author_id     uuid        not null references public.members(id) on delete cascade,
  content       text        not null,
  image_url     text,
  created_at    timestamptz not null default now()
);
```

### RLS Policies

- `communities`: SELECT public (actif), INSERT authenticated, UPDATE/DELETE owner ou admin
- `community_members`: SELECT si membre du groupe, INSERT si rejoint, UPDATE/DELETE admin seulement
- `community_posts`: SELECT si membre, INSERT si membre actif, DELETE si auteur ou admin du groupe

### Trigger

- `tg_community_member_count()` : met à jour `member_count` sur `communities` après insert/delete sur `community_members`
- `tg_set_updated_at_communities` : trigger `updated_at` standard

---

## 3. Architecture Côté Client

### Modèles Dart

- `lib/core/data/models/community.dart` — `Community` (id, name, description, coverUrl, category, visibility, memberCount, isMember, isAdmin)
- `lib/core/data/models/community_post.dart` — `CommunityPost` (id, communityId, authorId, authorName, authorAvatar, content, imageUrl, createdAt)

### Repository

- `lib/core/data/repositories/communities_repository.dart` — `CommunitiesRepository`
  - `fetchAll()` → `List<Community>`
  - `fetchById(id)` → `Community`
  - `fetchPosts(communityId)` → `List<CommunityPost>`
  - `create(data)` → `Community`
  - `join(communityId, memberId)` → void
  - `leave(communityId, memberId)` → void
  - `updateRole(communityId, memberId, role)` → void
  - `addPost(communityId, authorId, content, imageUrl)` → `CommunityPost`
  - `deletePost(postId)` → void

### Providers (Riverpod)

- `lib/core/data/providers/data_providers.dart`
  - `communitiesRepositoryProvider`
  - `communitiesProvider` → `FutureProvider<List<Community>>`
  - `communityProvider(communityId)` → `FutureProvider.family<Community, String>`
  - `communityPostsProvider(communityId)` → `FutureProvider.family<List<CommunityPost>, String>`
  - `communityMembersProvider(communityId)` → `FutureProvider.family<List<Member>, String>`
  - `isCommunityMemberProvider(communityId)` → `FutureProvider.family<bool, String>`

### Routes

- `/communities` → `CommunitiesScreen`
- `/community-detail` → `CommunityDetailScreen` (argument : communityId)
- `/create-community` → `CreateCommunityScreen`
- `/community-members` → `CommunityMembersScreen` (argument : communityId)

### Écrans

1. **`CommunitiesScreen`** — Catalogue avec barre de recherche, catégories, liste de groupes
2. **`CommunityDetailScreen`** — En-tête (couverture, nom, description, bouton rejoindre/quitter) + feed de posts
3. **`CreateCommunityScreen`** — Formulaire de création
4. **`CommunityMembersScreen`** — Liste des membres avec rôles
5. **`CommunitySettingsScreen`** — Modification du groupe, gestion des membres

### Navigation

- Nouvel onglet dans la `MainShell` (entre Carte et Messages) : icône `PhosphorIcons.usersThree`
- Dans le menu "Publier" (+) : option "Groupe/Communauté"

---

## 4. Ordre d'Implémentation

1. Migration Supabase (schéma + RLS + trigger)
2. Modèle `Community` + `CommunityPost`
3. Repository `CommunitiesRepository`
4. Providers Riverpod
5. Routes dans `AppRouter`
6. Écran `CommunitiesScreen` (catalogue)
7. Écran `CommunityDetailScreen` (feed)
8. Écran `CreateCommunityScreen` (création)
9. Intégration dans `MainShell` (onglet)
10. Menu "Publier" + option création de groupe
11. Écrans additionnels (membres, settings)

---

## 5. Notes Techniques

- Les `category` sont en texte libre pour l'instant (filtrage par catégorie côté client).
- `member_count` est dénormalisé et maintenu par trigger pour éviter un COUNT à chaque affichage.
- Les groupes privés : un membre avec `status='pending'` ne peut pas voir le feed ni poster.
- La suppression d'un groupe par l'admin supprime tous les posts et adhésions en cascade.
