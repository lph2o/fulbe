# 📋 Plan de Migration & Refactor — Fulɓe Connect

> **Date** : 9 juin 2026
> **Cible** : Remplacer les mocks par des repositories Supabase typés, durcir l'auth, ajouter les migrations SQL, nettoyer le code mort, et outiller la qualité (tests, logs, gestion d'erreurs).

---

## 🎯 Objectif Global

Transformer le projet d'un **prototype visuel avec mocks locaux** en une **application data-driven prête pour la production**, où :
- ✅ Toutes les données proviennent de Supabase (avec fallback mocks transparent en cas d'erreur)
- ✅ Les modèles sont **typés** (`fromJson` / `toJson`) avec validation
- ✅ L'auth est **robuste** (signOut global, gestion d'erreurs localisées, refresh token)
- ✅ Les **migrations SQL** sont versionnées
- ✅ Le code mort est nettoyé, les imports dupliqués supprimés
- ✅ Le code est **testable** (au moins smoke tests + tests de parsing)

---

## 📦 Périmètre — Inventaire des Mocks

| Fichier mock | Modèles exposés | Écran(s) consommateur(s) | Intégration Supabase actuelle |
|---|---|---|---|
| `mock_events.dart` | `Event`, `MockEvents` | `events_screen.dart` | ✅ Partielle (mapping manuel) |
| `mock_jobs.dart` | `Job`, `Transaction`, `MockJobs`, `MockFinances` | `jobs_screen.dart`, `finances_screen.dart` | ✅ Partielle (jobs) / ❌ finances (mock uniquement) |
| `mock_members.dart` | `Member`, `MemberCluster`, `MockMembers` | `directory_screen.dart`, `map/world_map_screen.dart`, `profile_screen.dart` | ❌ Aucun |
| `mock_posts.dart` | `Post`, `Announcement`, `MockPosts`, `MockAnnouncements` | `home_screen.dart` | ❌ Aucun |
| `mock_services.dart` | `MarketService`, `MockServices` | `marketplace_screen.dart` | ✅ Partielle |

**Migrations SQL à produire** : 7 tables (`events`, `jobs`, `marketplace_services`, `books`, `members`, `posts`, `announcements`, + `transactions` pour les finances).

---

## 🗂️ Architecture Cible

```
lib/
├── core/
│   ├── data/
│   │   ├── supabase_fetchers.dart        # Helper bas niveau (existe, à étendre)
│   │   ├── mock/                          # Déplacé depuis la racine
│   │   │   ├── mock_events.dart
│   │   │   ├── mock_jobs.dart
│   │   │   ├── mock_members.dart
│   │   │   ├── mock_posts.dart
│   │   │   └── mock_services.dart
│   │   ├── models/                        # Modèles typés (fromJson/toJson)
│   │   │   ├── event.dart
│   │   │   ├── job.dart
│   │   │   ├── member.dart
│   │   │   ├── post.dart
│   │   │   ├── service.dart
│   │   │   └── transaction.dart
│   │   ├── repositories/                  # Couche métier (Supabase + fallback)
│   │   │   ├── events_repository.dart
│   │   │   ├── jobs_repository.dart
│   │   │   ├── members_repository.dart
│   │   │   ├── posts_repository.dart
│   │   │   ├── services_repository.dart
│   │   │   ├── finances_repository.dart
│   │   │   └── books_repository.dart
│   │   └── result.dart                    # Sealed class Success/Failure
│   ├── auth/
│   │   └── auth_service.dart              # Wrapper auth (signOut, refresh, current user)
│   └── errors/
│       └── app_exception.dart             # Hiérarchie d'erreurs localisables
├── features/
│   └── ... (consommateurs des repositories)
└── ...
```

---

## ✅ Tâches Détaillées

### **Phase 1 — Fondations (critique)**

#### 1.1 Créer la hiérarchie d'erreurs `AppException`
- [ ] Créer `lib/core/errors/app_exception.dart`
- [ ] Définir `AppException` (abstract) avec `message` localisé et `code`
- [ ] Sous-classes : `NetworkException`, `AuthException`, `NotFoundException`, `ValidationException`, `ServerException`
- [ ] Helper `getLocalizedMessage(AppException e)` en français

#### 1.2 Créer le type `Result<T>` (sealed)
- [ ] Créer `lib/core/data/result.dart`
- [ ] Définir `sealed class Result<T> { Success<T> | Failure<T> }`
- [ ] Helpers : `Result.success(value)`, `Result.failure(exception)`, `map`, `flatMap`, `when`

#### 1.3 Externaliser la config Supabase
- [ ] Déplacer URL/clé depuis `main.dart` vers `--dart-define`
- [ ] Modifier `main.dart` pour lire `String.fromEnvironment('SUPABASE_URL')` / `SUPABASE_PUBLISHABLE_KEY`
- [ ] Documenter dans `.env.example` (déjà existant, à enrichir)

---

### **Phase 2 — Modèles typés (critique)**

#### 2.1 Modèle `Event` (`lib/core/data/models/event.dart`)
- [ ] Réécrire la classe avec champs `final` typés
- [ ] Ajouter `factory Event.fromJson(Map<String, dynamic> json)`
- [ ] Ajouter `Map<String, dynamic> toJson()`
- [ ] Helper `_parseDate(dynamic)` qui accepte `DateTime | String | null`
- [ ] Helper `_parseInt(dynamic)` avec fallback 0
- [ ] Conserver `copyWith` existant
- [ ] Ajouter `==` / `hashCode` pour la testabilité
- [ ] Tests unitaires : `test/models/event_test.dart` (3 cas : parsing complet, partiel, avec erreurs)

#### 2.2 Modèle `Job` (`lib/core/data/models/job.dart`)
- [ ] Idem : `fromJson` / `toJson` avec snake_case ↔ camelCase
- [ ] Helper `_nullableString` pour gérer les `String?` proprement
- [ ] Tests : `test/models/job_test.dart`

#### 2.3 Modèle `Member` (`lib/core/data/models/member.dart`)
- [ ] Idem
- [ ] **Subtilité** : `MemberCluster` reste lié (cluster géographique pour la map)
- [ ] Tests : `test/models/member_test.dart`

#### 2.4 Modèle `Post` + `Announcement` (`lib/core/data/models/post.dart`)
- [ ] Modèles regroupés (même fichier)
- [ ] Tests : `test/models/post_test.dart`

#### 2.5 Modèle `MarketService` (`lib/core/data/models/service.dart`)
- [ ] Idem, helper `_parseDouble` pour rating
- [ ] Tests : `test/models/service_test.dart`

#### 2.6 Modèle `Transaction` (`lib/core/data/models/transaction.dart`)
- [ ] Idem
- [ ] Tests : `test/models/transaction_test.dart`

#### 2.7 Modèle `Book` (nouveau, `lib/core/data/models/book.dart`)
- [ ] Modèle déduit du parsing existant dans `library_screen.dart`
- [ ] Champs : `id, title, author, emoji, colorHex, categoryIndex`
- [ ] Tests : `test/models/book_test.dart`

---

### **Phase 3 — Repositories (critique)**

Chaque repository suit le pattern :
```dart
abstract class XRepository {
  Future<Result<List<X>>> getAll();
  Future<Result<X?>> getById(String id);
  Future<Result<X>> create(X item);
  Future<Result<X>> update(X item);
  Future<Result<void>> delete(String id);
}

class SupabaseXRepository implements XRepository { ... }
```

#### 3.1 `EventsRepository`
- [ ] Interface dans `lib/core/data/repositories/events_repository.dart`
- [ ] Implémentation Supabase : table `events`
- [ ] Gestion des colonnes : `id, title, date, location, category, description, image_url, attendee_count`
- [ ] Tests : `test/repositories/events_repository_test.dart` (avec Supabase mocké)

#### 3.2 `JobsRepository`
- [ ] Idem pour table `jobs`

#### 3.3 `MembersRepository`
- [ ] Idem pour table `members` (et `member_clusters` pour la map)
- [ ] Requête avec relation `member_skills`

#### 3.4 `PostsRepository`
- [ ] Idem pour tables `posts` + `announcements`
- [ ] Méthode dédiée `getFeed({limit, offset})` avec jointure author

#### 3.5 `ServicesRepository`
- [ ] Idem pour table `marketplace_services`

#### 3.6 `FinancesRepository`
- [ ] Idem pour tables `transactions` + `community_projects` + `subscriptions`
- [ ] Méthodes : `getTransactions()`, `getProjects()`, `getBalance()`

#### 3.7 `BooksRepository`
- [ ] Idem pour table `books`
- [ ] Méthode : `getRecentBooks({category})`

---

### **Phase 4 — Migrations SQL (critique)**

Créer `supabase/migrations/` avec fichiers versionnés :

#### 4.1 `20260609_001_init_schema.sql`
- [ ] Extensions : `pgcrypto`, `uuid-ossp`
- [ ] Table `members` (id, full_name, profession, city, country, avatar_url, is_verified, created_at)
- [ ] Table `member_skills` (member_id, skill)
- [ ] Table `member_clusters` (id, name, country, count, lat_pct, lng_pct)
- [ ] Table `posts` (id, author_id → members, content, image_url, likes_count, comments_count, created_at)
- [ ] Table `announcements` (id, chip_label, title, description, cta_label, cta_route, created_at)
- [ ] Table `events` (id, title, date, location, category, description, image_url, attendee_count)
- [ ] Table `event_rsvps` (event_id, user_id, created_at)
- [ ] Table `jobs` (id, title, company, company_initials, location, type, domain, posted_ago, badge, badge_type)
- [ ] Table `marketplace_services` (id, category, category_icon, title, description, rating, review_count, price, price_label, cta_label, image_url)
- [ ] Table `books` (id, title, author, emoji, color_hex, category_index)
- [ ] Table `transactions` (id, user_id, label, amount, method, occurred_at)
- [ ] Table `community_projects` (id, title, location, current_amount, target_amount, currency, icon, color)
- [ ] Table `subscriptions` (user_id, plan, started_at, next_due_at, amount)
- [ ] Table `conversations` + `messages` (pour la messagerie future)

#### 4.2 `20260609_002_rls_policies.sql`
- [ ] Activer RLS sur toutes les tables
- [ ] Policy `SELECT` : tout le monde (annuaire public)
- [ ] Policy `INSERT/UPDATE/DELETE` : auteur uniquement (`auth.uid() = user_id`)
- [ ] Policy `events` : RSVP libre pour utilisateurs authentifiés
- [ ] Policy `members` : chacun peut éditer sa propre fiche uniquement

#### 4.3 `20260609_003_seed_dev_data.sql`
- [ ] INSERT des mocks actuels comme seed pour le dev (option `--if not exists`)

#### 4.4 `20260609_004_functions_triggers.sql`
- [ ] Trigger `update_attendee_count` sur RSVP
- [ ] Trigger `updated_at` auto sur toutes les tables
- [ ] Vue `v_member_profiles` (jointure members + skills)
- [ ] Vue `v_event_popularity` (tri par attendee_count)

---

### **Phase 5 — Nettoyage du code mort**

#### 5.1 `lib/features/home/home_screen.dart`
- [ ] Supprimer l'import dupliqué : `import '../../core/data/mock_posts.dart';` (ligne dupliquée)
- [ ] Supprimer l'import inutilisé : `import 'package:supabase_flutter/supabase_flutter.dart';`
- [ ] Supprimer l'import inutilisé : `import 'package:flutter/foundation.dart';` (n'existe pas dans ce fichier — vérifier)
- [ ] Garder uniquement les imports utilisés

#### 5.2 `lib/features/library/library_screen.dart`
- [ ] Supprimer l'import inutilisé : `import 'package:flutter/foundation.dart';`

#### 5.3 `lib/features/events/events_screen.dart`
- [ ] Vérifier que tous les imports sont utilisés

#### 5.4 Lancer `dart fix --apply` et `flutter analyze` après chaque phase
- [ ] Zéro warning toléré

---

### **Phase 6 — Auth hardening**

#### 6.1 `lib/core/auth/auth_service.dart`
- [ ] Créer wrapper auth avec méthodes :
  - `Stream<AuthState> get authStateChanges`
  - `User? get currentUser`
  - `Future<void> signOut()` (avec cleanup local)
  - `Future<void> refreshSession()`
- [ ] Helper `getUserMetadata<T>(String key)` typé

#### 6.2 Logout global
- [ ] Déplacer le bouton de logout depuis `profile_screen.dart` vers une action dans l'AppBar
- [ ] Permettre le logout depuis n'importe quel écran
- [ ] Confirmation dialog réutilisable

#### 6.3 Gestion d'erreurs localisées
- [ ] Mapper tous les `AuthException` Supabase → `AppException` en français
- [ ] Helper `localizeAuthError(AuthException e)` (déjà partiellement fait dans `auth_screen.dart` — à extraire)

---

### **Phase 7 — Intégration dans les écrans**

Pour chaque écran consommateur, remplacer :
```dart
// AVANT (parsing manuel)
final rows = await SupabaseFetchers.selectAll('events');
final parsed = rows.map((row) { ... }).toList();

// APRÈS (via repository)
final result = await eventsRepository.getAll();
result.when(
  success: (events) => setState(() => _events = events),
  failure: (e) => showSnackBar(e.message),
);
```

#### 7.1 `events_screen.dart`
- [ ] Injecter `EventsRepository` (via constructeur pour testabilité)
- [ ] `initState` → `await eventsRepository.getAll()`
- [ ] Gérer `loading` / `error` / `empty` states (déjà partiellement présent)

#### 7.2 `jobs_screen.dart`
- [ ] Idem

#### 7.3 `marketplace_screen.dart`
- [ ] Idem

#### 7.4 `library_screen.dart`
- [ ] Idem pour `_HorizontalBookRow` + ajouter le repository au parent

#### 7.5 `home_screen.dart`
- [ ] Idem (posts + announcements)
- [ ] Ajouter le FAB "Composer" (actuellement no-op)

#### 7.6 `directory_screen.dart`
- [ ] Idem (members)

#### 7.7 `map/world_map_screen.dart`
- [ ] Idem (member_clusters)

#### 7.8 `finances_screen.dart`
- [ ] Idem (transactions + projects + balance)

---

### **Phase 8 — State management (optionnel mais recommandé)**

> Décision à confirmer : **Riverpod** ou rester sur `setState` ?

#### 8.1 Si Riverpod choisi
- [ ] Ajouter `flutter_riverpod` dans `pubspec.yaml`
- [ ] Créer `lib/core/providers/repository_providers.dart`
- [ ] Convertir les écrans Stateful → ConsumerStatefulWidget
- [ ] Avantages : cache, invalidation, async propre avec `AsyncValue<T>`

#### 8.2 Si `setState` conservé
- [ ] Documenter le pattern dans `docs/PATTERNS.md`
- [ ] Centraliser l'instanciation des repositories dans `main.dart`

---

### **Phase 9 — Tests**

#### 9.1 Tests unitaires modèles (6 fichiers)
- [ ] `test/models/event_test.dart` — parsing complet / partiel / avec null
- [ ] `test/models/job_test.dart`
- [ ] `test/models/member_test.dart`
- [ ] `test/models/post_test.dart`
- [ ] `test/models/service_test.dart`
- [ ] `test/models/transaction_test.dart`
- [ ] `test/models/book_test.dart`

#### 9.2 Tests repositories (avec Supabase mocké)
- [ ] `test/repositories/events_repository_test.dart`
- [ ] `test/repositories/jobs_repository_test.dart`
- [ ] etc.

#### 9.3 Tests widget (smoke tests)
- [ ] `test/widget_test.dart` — remplacer le test par défaut
  - Test : l'app build sans crash
  - Test : `WelcomeScreen` s'affiche en mode non-authentifié
  - Test : `MainShell` change d'onglet correctement
  - Test : `EventsScreen` charge les mocks en fallback

#### 9.4 Couverture
- [ ] Objectif : `flutter test --coverage` → ≥ 60% sur `lib/core/data/`

---

### **Phase 10 — Qualité & DX**

#### 10.1 Lint
- [ ] Étendre `analysis_options.yaml` :
  - `prefer_const_constructors`
  - `prefer_final_locals`
  - `always_declare_return_types`
  - `avoid_print` (utiliser un logger)
  - `require_trailing_commas`
- [ ] `flutter analyze` → 0 issue

#### 10.2 Logger centralisé
- [ ] Créer `lib/core/logging/app_logger.dart`
- [ ] Wrapper autour de `dart:developer log()` + buffering
- [ ] Remplacer tous les `print()` et `debugPrint()`

#### 10.3 Constantes externalisées
- [ ] Créer `lib/core/constants/app_constants.dart`
- [ ] Centraliser URLs (Supabase, avatars Unsplash placeholder), timeouts, pagination defaults

#### 10.4 Documentation
- [ ] Compléter le `README.md` (sections : setup, env vars, run, test, build, deploy)
- [ ] Ajouter `docs/ARCHITECTURE.md` (schéma + choix techniques)
- [ ] Ajouter `docs/DATA_MODEL.md` (schéma DB + relations)

---

## 🚦 Priorisation (MoSCoW)

### 🔴 MUST (à faire dans cette session si périmètre confirmé)
- Phase 1 (fondations : `Result`, `AppException`, config externalisée)
- Phase 2 (modèles typés avec `fromJson`/`toJson`)
- Phase 5 (nettoyage code mort)
- Phase 6.1-6.3 (auth hardening de base)

### 🟡 SHOULD (à faire dans cette session si temps)
- Phase 3 (repositories — au moins 2-3 pour démontrer le pattern)
- Phase 7.1-7.4 (intégration dans 2-3 écrans)
- Phase 9.1 (tests des modèles)

### 🟢 COULD (à faire ultérieurement)
- Phase 4 (migrations SQL complètes — produit un gros fichier, long à valider)
- Phase 8 (state management global)
- Phase 9.2-9.3 (tests repositories + widgets)
- Phase 10 (lint durci + docs)

### ⚪ WON'T (cette session)
- Refonte UI
- Internationalisation réelle (Fulfulde/English)
- Implémentation des écrans `Messages` / `Learning` data-driven
- Pipeline CI/CD

---

## ⏱️ Estimation de Temps

| Phase | Étendue | Estimation |
|---|---|---|
| 1. Fondations | Petite | 20 min |
| 2. Modèles typés (×7) | Moyenne | 45 min |
| 3. Repositories (×7) | Moyenne | 60 min |
| 4. Migrations SQL | Grande | 40 min |
| 5. Nettoyage | Petite | 10 min |
| 6. Auth hardening | Petite-Moyenne | 25 min |
| 7. Intégration écrans (×8) | Moyenne | 50 min |
| 8. State management | Moyenne | 30 min (si choisi) |
| 9. Tests | Grande | 45 min |
| 10. Qualité & DX | Petite | 15 min |
| **TOTAL (toutes phases)** | — | **~5h 40min** |

---

## 🎬 Prochaines Étapes (à confirmer avec l'utilisateur)

1. **Quel périmètre exécuter maintenant ?**
   - Option A : MUST + SHOULD (≈ 3h30, livraison la plus utile)
   - Option B : MUST uniquement (≈ 1h30, fondamentaux posés)
   - Option C : Tout (≈ 5h40, refactor complet)
   - Option D : À la carte (vous choisissez les phases)

2. **State management ?**
   - Garder `setState` (statu quo, plus rapide)
   - Migrer vers **Riverpod** (recommandé, plus propre)

3. **Migrations SQL ?**
   - Produire le SQL complet maintenant ?
   - Ou laisser en placeholder TODO ?

4. **Tests ?**
   - Smoke tests uniquement ?
   - Tests unitaires modèles + repositories ?
   - Pas de tests cette session ?

5. **Mocks : à supprimer ou à garder en fallback ?**
   - Recommandation : **garder en fallback** derrière les repositories
   - Mais renommer `MockXxx` → `XxxFallback` pour clarifier l'intention

---

**👤 Auteur du plan** : Analyse automatisée du projet
**📅 Prochaine action** : Confirmation utilisateur du périmètre
