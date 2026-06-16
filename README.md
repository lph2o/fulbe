# Fulɓe Connect

> Plateforme communautaire mondiale pour la diaspora Peule — membres, événements,
> emplois, marketplace, finances, messagerie, apprentissage et patrimoine.

Fulɓe Connect est une application **Flutter** (iOS · Android · macOS · Windows · Linux · Web)
alimentée par un backend **Supabase** (Postgres + Auth + Storage + Realtime + RLS).

---

## 📑 Sommaire

1. [Pré-requis](#-pré-requis)
2. [Quickstart](#-quickstart)
3. [Configuration des variables d'environnement](#-configuration-des-variables-denvironnement)
4. [Initialisation du projet Supabase](#-initialisation-du-projet-supabase)
5. [Application des migrations SQL](#-application-des-migrations-sql)
6. [Lancer l'application](#-lancer-lapplication)
7. [Build (production)](#-build-production)
8. [Tests & qualité](#-tests--qualité)
9. [Dépannage](#-dépannage)
10. [Structure du projet](#-structure-du-projet)
11. [Documentation complémentaire](#-documentation-complémentaire)

---

## ✅ Pré-requis

| Outil | Version recommandée | Vérification |
|---|---|---|
| Flutter SDK | ≥ 3.24 (Dart ≥ 3.5) | `flutter --version` |
| Git | ≥ 2.30 | `git --version` |
| Supabase CLI *(optionnel mais recommandé)* | ≥ 1.200 | `supabase --version` |
| PostgreSQL client *(optionnel)* | ≥ 14 | `psql --version` |
| Un compte Supabase | — | [app.supabase.com](https://app.supabase.com) |

> 💡 **Pour les migrations**, l'une des trois options du `supabase/README.md` suffit :
> Supabase CLI, Dashboard SQL editor, ou `psql` direct.

---

## ⚡ Quickstart

Cette section vous guide du clone à l'app qui tourne en moins de 5 minutes.
Pour les contributeurs qui découvrent le projet, c'est **le seul passage
obligatoire** à lire avant de lancer quoi que ce soit.

### 1. Cloner et installer les dépendances

```bash
git clone <repo-url> fulbe
cd fulbe
flutter pub get
```

### 2. Configurer Supabase (obligatoire)

Sans configuration, **l'app n'ira pas plus loin que l'écran d'erreur**
dédié — voir [§ Comportement sans configuration](#-comportement-sans-configuration) plus bas.

```bash
# Copier le template documenté (`.env.example` est commité, `.env` est gitignored)
cp .env.example .env

# Éditer .env avec vos credentials
$EDITOR .env
```

Les deux variables à renseigner (depuis [app.supabase.com](https://app.supabase.com)
→ votre projet → **Project Settings → API**) :

| Variable | Source dans le dashboard | Obligatoire |
|---|---|---|
| `SUPABASE_URL` | *Project URL* | ✅ |
| `SUPABASE_PUBLISHABLE_KEY` | *Publishable key* (`sb_publishable_…`) ou *anon public* (legacy `eyJ…`) | ✅ |

> 📄 Le template complet et commenté est dans [`.env.example`](.env.example) :
> descriptions, exemples, avertissements de sécurité, emplacement dashboard.

### 3. (Premier lancement uniquement) Appliquer les migrations

Voir [§ Application des migrations SQL](#-application-des-migrations-sql).
Pas nécessaire à chaque lancement, seulement quand le schéma change.

### 4. Lancer l'app

```bash
flutter run --dart-define-from-file=.env
```

> 🔁 Après modification du `.env`, faites un `flutter clean && flutter pub get`
> puis relancez : les `--dart-define` sont **compilés en dur** dans le binaire.

### Comportement sans configuration

Pour éviter aux nouveaux contributeurs de buter sur une
`SocketException: Failed host lookup: 'placeholder.supabase.co'` opaque,
l'app détecte la configuration manquante **avant** d'initialiser Supabase.

Si vous lancez l'app **sans** avoir rempli `.env` (ou sans `--dart-define`),
`lib/main.dart` intercepte la situation et affiche un écran dédié —
**« Configuration Supabase manquante »** — au lieu de crasher.

Cet écran (`lib/features/onboarding/config_error_screen.dart`) vous montre :

- 🔍 **L'URL et la clé actuellement détectées**, surlignées en rouge si ce
  sont encore les valeurs placeholder
- 📋 **Les 3 étapes pour corriger** : créer `.env`, renseigner les
  credentials, relancer avec `--dart-define-from-file=.env`
- 📎 **Un bouton « Copier la commande d'exemple »** qui met dans le
  presse-papier :

  ```bash
  flutter run \
    --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
    --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
  ```

La détection vit dans [`lib/core/constants/app_constants.dart`](lib/core/constants/app_constants.dart)
(voir `AppConstants.hasSupabaseConfig`). Elle couvre à la fois l'URL
par défaut `https://placeholder.supabase.co` et toute URL contenant
encore le mot-clé `placeholder`.

> 💡 Si vous voyez cet écran alors que **vous pensez** avoir configuré
> `.env`, c'est presque toujours un cache de build : lancez
> `flutter clean` puis relancez — les `--dart-define` sont compilés
> en dur et ne se mettent pas à jour à chaud.

---

## 🔐 Configuration des variables d'environnement

L'application lit ses secrets **au moment de la compilation** via
[`String.fromEnvironment`](https://api.dart.dev/stable/dart-core/String/String.fromEnvironment.html)
— pas d'appel réseau pour charger un `.env` au runtime.

### Fichier `.env.example` (commité)

Un template documenté est fourni à la racine. **Copiez-le** en `.env` (jamais commité) :

```bash
cp .env.example .env
```

### Variables reconnues

| Variable | Obligatoire | Description | Exemple |
|---|---|---|---|
| `SUPABASE_URL` | ✅ | URL de votre projet Supabase (sans `/` final) | `https://abc.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | ✅ | Clé publishable (`sb_publishable_…`) ou anon (`eyJ…`) | `sb_publishable_xxx…` |

> ⚠️ **Ne jamais** commiter la clé `service_role` dans une app mobile.
> Elle n'est utilisée que côté serveur.

### Lire les variables dans l'app

Toute la configuration vit dans `lib/core/constants/app_constants.dart` :

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://placeholder.supabase.co',
);
```

Si une variable manque au build, la valeur *placeholder* est utilisée — d'où
le crash DNS `placeholder.supabase.co` que vous avez peut-être vu.

### Fichiers `.gitignore`-és

| Fichier | Statut Git |
|---|---|
| `.env` | ❌ Ignoré (vos secrets) |
| `.env.*` (sauf `.env.example`) | ❌ Ignoré (variantes locales) |
| `.env.example` | ✅ Commité (template documenté) |

---

## 🗄️ Initialisation du projet Supabase

1. Créez un projet sur [app.supabase.com](https://app.supabase.com) (région la plus
   proche de vos utilisateurs, ex. `eu-west-1` pour la diaspora européenne).
2. **Project Settings → API** : notez
   - `Project URL` → à mettre dans `SUPABASE_URL`
   - `Publishable key` (nouveau) ou `anon public` (legacy) → à mettre dans `SUPABASE_PUBLISHABLE_KEY`
3. **Authentication → Providers** : laissez `Email` activé (c'est ce qu'utilise
   `lib/features/auth/auth_screen.dart`). Désactivez la confirmation email en dev
   pour itérer plus vite, ou gardez-la activée pour tester le flux OTP.

---

## 📜 Application des migrations SQL

Toutes les migrations sont versionnées dans `supabase/migrations/` (13 tables,
RLS, triggers, vues, seed data, organisations & chapitres). Voir
[`supabase/README.md`](supabase/README.md) pour le détail complet.

### Option A — Supabase CLI (recommandé)

```bash
# Lier le repo local à votre projet Supabase
supabase link --project-ref <votre-project-ref>

# Appliquer toutes les migrations en attente
supabase db push
```

### Option B — Dashboard Supabase

Dans **SQL Editor** du dashboard, exécutez les fichiers dans l'ordre :

1. `000_dev_reset.sql` *(uniquement sur un projet vierge)*
2. `20260609_001_init_schema.sql`
3. `20260609_002_rls_policies.sql`
4. `20260609_003_seed_dev_data.sql`
5. `20260609_004_functions_triggers.sql`
6. `20260609_005_orgs_chapters.sql`
7. `20260609_006_seed_organizations.sql`

### Option C — psql direct

```bash
psql "$DATABASE_URL" \
  -f supabase/migrations/20260609_001_init_schema.sql \
  -f supabase/migrations/20260609_002_rls_policies.sql \
  -f supabase/migrations/20260609_003_seed_dev_data.sql \
  -f supabase/migrations/20260609_004_functions_triggers.sql \
  -f supabase/migrations/20260609_005_orgs_chapters.sql \
  -f supabase/migrations/20260609_006_seed_organizations.sql
```

### Vérification rapide

```sql
-- Doit retourner ≥ 13 tables
select count(*) from information_schema.tables
 where table_schema = 'public' and table_type = 'BASE TABLE';

-- Doit retourner 8 membres après seed
select count(*) from public.members;
```

---

## ▶️ Lancer l'application

### Ligne de commande (toutes plateformes)

```bash
# Méthode recommandée : depuis le fichier .env
flutter run --dart-define-from-file=.env

# Méthode explicite (sans fichier .env)
flutter run \
  --dart-define=SUPABASE_URL=https://abc.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

> L'argument `--dart-define-from-file` lit le fichier `.env` ligne par ligne
> et injecte chaque `KEY=VALUE` comme `--dart-define=KEY=VALUE`.

### Plateformes spécifiques

```bash
flutter run -d chrome        --dart-define-from-file=.env   # Web
flutter run -d ios           --dart-define-from-file=.env   # iOS Simulator
flutter run -d macos         --dart-define-from-file=.env   # macOS
flutter run -d android       --dart-define-from-file=.env   # Android emulator
```

### VS Code (`.vscode/launch.json`)

Un exemple prêt à l'emploi est fourni dans [`.vscode/launch.json.example`](.vscode/launch.json.example).
Copiez-le en `.vscode/launch.json` pour pouvoir **F5 / ▶ Run** sans ligne de commande :

```bash
cp .vscode/launch.json.example .vscode/launch.json
```

---

## 📦 Build (production)

Les variables d'environnement doivent être fournies au build :

```bash
# Android (APK)
flutter build apk \
  --dart-define-from-file=.env \
  --release

# Android (App Bundle pour Play Store)
flutter build appbundle \
  --dart-define-from-file=.env \
  --release

# iOS
flutter build ios \
  --dart-define-from-file=.env \
  --release

# Web (avec variables injectées au build time)
flutter build web \
  --dart-define-from-file=.env \
  --release
```

> ⚠️ Les valeurs `--dart-define` sont **compilées en dur** dans le binaire
> Flutter. Pour des secrets rotatifs, privilégiez un backend (Supabase Edge
> Function) qui renvoie la config au runtime.

---

## 🧪 Tests & qualité

```bash
# Analyse statique (lint + types)
flutter analyze

# Tests unitaires + widgets
flutter test

# Tests avec couverture
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

Tests disponibles (cf. `test/` et `MIGRATION_PLAN.md` § Phase 9) :

- `test/core/data/models_test.dart` — parsing `fromJson` / `toJson`
- `test/core/data/parsers_test.dart` — helpers de parsing
- `test/core/errors/result_and_exceptions_test.dart` — `Result<T>` + `AppException`
- `test/widget_test.dart` — smoke test de l'app

---

## 🔔 Notifications push (appels entrants)

### Prérequis Firebase

1. Créez un projet Firebase sur [console.firebase.google.com](https://console.firebase.google.com).
2. Ajoutez les applications Android et iOS à votre projet Firebase.
3. Téléchargez les fichiers de configuration :
   - Android : `google-services.json` → placez-le dans `android/app/`
   - iOS : `GoogleService-Info.plist` → placez-le dans `ios/Runner/` via Xcode
4. Activez **Cloud Messaging** dans Firebase Console → votre projet → Cloud Messaging.
5. Copiez la **Server key** (legacy) depuis Firebase Console → Project Settings → Cloud Messaging → Server key.

### Configuration Supabase

La migration `20260615_031_member_fcm_tokens.sql` utilise un trigger SQL pour envoyer les notifications FCM. Avant de l'appliquer, vous devez configurer deux choses :

1. **Activer l'extension `pg_net`** (permet les requêtes HTTP depuis PostgreSQL) :
   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_net;
   ```

2. **Configurer la clé serveur FCM** dans les paramètres de la base de données :
   ```sql
   ALTER DATABASE postgres SET app.fcm_server_key = 'YOUR_LEGACY_SERVER_KEY';
   ```
   > ⚠️ Utilisez la **Legacy server key** (pas la clé V1). Le trigger utilise l'API legacy FCM.

### Comportement

- Quand un appel est initié, le trigger `notify_call_invite` envoie une notification FCM à tous les appareils du destinataire.
- En **foreground**, la notification est affichée comme une notification locale avec les actions **Accepter** / **Refuser**.
- En **background**, la notification native s'affiche. Tapper **Accepter** ouvrira l'app et l'écran d'appel entrant. Tapper **Refuser** mettra à jour le statut de l'appel dans Supabase.

---

## 🛟 Dépannage

### `ClientException: Failed host lookup: 'placeholder.supabase.co'`

Vous n'avez pas lancé l'app avec `--dart-define-from-file=.env` (ou votre `.env`
contient encore la valeur placeholder). Voir la section
[Configuration des variables d'environnement](#-configuration-des-variables-denvironnement).

```bash
# Vérifier que le fichier .env est bien rempli
cat .env

# Re-lancer avec les variables
flutter run --dart-define-from-file=.env
```

### `AuthException: Invalid login credentials`

- Vérifiez que l'email existe dans **Authentication → Users** du dashboard.
- Si la confirmation email est activée, l'utilisateur doit d'abord cliquer le
  lien reçu par email (ou vous pouvez le confirmer manuellement depuis le dashboard).

### `SocketException: Connection refused` sur Android emulator

L'emulator Android résout `localhost` en `10.0.2.2` pour atteindre la machine
hôte. Si vous utilisez Supabase Cloud, l'URL publique fonctionne directement ;
si vous utilisez un Supabase local, voir [la doc](https://supabase.com/docs/guides/local-development).

### Les `dart-define` semblent ignorés

Ils sont **compilés en dur** : un `flutter clean` + `flutter pub get` est
parfois nécessaire après modification du `.env` :

```bash
flutter clean
flutter pub get
flutter run --dart-define-from-file=.env
```

### Erreurs de type `permission denied for table members`

Les policies RLS sont activées par défaut. Vérifiez que vous êtes bien
authentifié côté client (session non nulle) et que le JWT contient le `sub` (user id).
Voir `supabase/migrations/20260609_002_rls_policies.sql` pour les détails.

---

## 🗂️ Structure du projet

```
fulbe/
├── lib/
│   ├── main.dart                       # Bootstrap + Supabase.initialize
│   ├── core/
│   │   ├── auth/                       # AuthService (wrapper Supabase Auth)
│   │   ├── constants/                  # AppConstants (URL, timeouts, etc.)
│   │   ├── data/
│   │   │   ├── models/                 # Event, Job, Member, Post, … (typés)
│   │   │   ├── repositories/           # Couche d'accès données
│   │   │   ├── providers/              # Riverpod providers
│   │   │   ├── parsers.dart
│   │   │   ├── supabase_fetchers.dart
│   │   │   └── result.dart             # Sealed class Success/Failure
│   │   ├── errors/                     # AppException + sous-types
│   │   ├── logging/                    # Logger centralisé
│   │   ├── navigation/                 # Router + MainShell
│   │   ├── services/                   # LocationService, …
│   │   └── theme/                      # Couleurs, texte, espacement
│   ├── features/                       # Un dossier par écran / domaine
│   │   ├── auth/  home/  directory/  map/  events/  jobs/
│   │   ├── marketplace/  library/  finances/  learning/  messages/
│   │   ├── profile/  onboarding/
│   └── shared/widgets/                 # Composants UI réutilisables
├── supabase/
│   ├── migrations/                     # SQL versionnés (à appliquer en ordre)
│   ├── apply_migrations.sh
│   └── README.md
├── test/                               # Tests unitaires + widgets
├── assets/                             # Fonts, designs Stitch exportés
├── docs/                               # Plans, design docs
├── .env.example                        # ⚠️ Template (commité)
├── .env                                # 🔒 Vos secrets (gitignored)
├── pubspec.yaml
└── README.md                           # ← vous êtes ici
```

---

## 📚 Documentation complémentaire

| Fichier | Contenu |
|---|---|
| [`MIGRATION_PLAN.md`](MIGRATION_PLAN.md) | Plan de refactor : mocks → repositories Supabase, durcissement auth, tests |
| [`docs/plans/2026-06-09-orgs-chapters-design.md`](docs/plans/2026-06-09-orgs_chapters-design.md) | Design du réseau d'associations & chapitres |
| [`supabase/README.md`](supabase/README.md) | Détail des migrations SQL, sécurité RLS, vues |
| [`assets/stitch_ful_e_connect_platform/ful_e_connect_prd.md`](assets/stitch_ful_e_connect_platform/ful_e_connect_prd.md) | PRD produit + plan des écrans |
| [`.agents/skills/supabase/SKILL.md`](.agents/skills/supabase/SKILL.md) | Bonnes pratiques Supabase (auth, RLS, Realtime) |

---

## 📄 Licence

Propriétaire — © Fulɓe Connect. Tous droits réservés.
