# Module Événements Fulɓe Connect — Plan de Conception

> **Date :** 12 juin 2026  
> **Auteur :** Fulɓe Connect Engineering  
> **Statut :** MVP en cours — Phase 0 validée, Phase 3+4 validée, implémentation partielle

---

## 📋 Table des matières

1. [Phase 0 — Vision Produit](#phase-0--vision-produit)
2. [Phase 1 — Recherche & Benchmark](#phase-1--recherche--benchmark)
3. [Phase 3 — Inventaire des Fonctionnalités](#phase-3--inventaire-des-fonctionnalités)
4. [Phase 4 — Architecture UX (Écrans)](#phase-4--architecture-ux-écrans)
5. [État des lieux du code](#état-des-lieux-du-code)
6. [Priorités immédiates](#priorités-immédiates)

---

## Phase 0 — Vision Produit

### 1. Mission du module

> **Devenir le point de ralliement numérique de la diaspora Fulɓe pour organiser, découvrir et vivre des événements communautaires — avant, pendant, et après.**

Le module Événements n'est pas un énième clone d'Eventbrite. Il est la **colonne vertébrale communautaire** de Fulɓe Connect : l'endroit où les liens numériques (posts, messagerie, annuaire) se transforment en rencontres physiques, puis en souvenirs partagés qui nourrissent le réseau.

### 2. Objectifs Business

| # | Objectif | Mesure |
|---|----------|--------|
| B1 | **Rétention** : que les utilisateurs reviennent pour les événements (avant/pendant/après) | DAU/MAU, taux de rétention J30 |
| B2 | **Croissance organique** : chaque événement = acquisition (invitations, partages, photos) | Nouveaux inscrits attribués aux événements |
| B3 | **Monétisation future** : poser les fondations pour des événements payants (billets, sponsoring) | Volume d'événements créés, taux de remplissage |
| B4 | **Activation des membres passifs** : convertir les "lecteurs" en "participants" | Taux de conversion : visite → RSVP |

### 3. Objectifs Utilisateurs

#### Pour l'Organisateur
| # | Besoin |
|---|--------|
| U1 | Créer un événement en < 2 minutes |
| U2 | Voir qui vient, communiquer avec les inscrits |
| U3 | Gérer les inscriptions (capacité, liste d'attente) |
| U4 | Recevoir des feedbacks après l'événement |
| U5 | Faire grandir sa communauté (groupe post-événement) |

#### Pour le Participant
| # | Besoin |
|---|--------|
| U6 | Découvrir les événements pertinents (proximité, intérêts) |
| U7 | S'inscrire en 1 clic |
| U8 | Recevoir des rappels intelligents |
| U9 | Voir qui d'autre participe (networking) |
| U10 | Revivre l'événement (photos, replay, groupe) |

### 4. KPI (Key Performance Indicators)

| Catégorie | KPI | Cible MVP |
|-----------|-----|-----------|
| **Création** | Nombre d'événements créés / mois | > 10 |
| **Engagement** | Taux de RSVP (vues → inscriptions) | > 20% |
| **Engagement** | Taux de participation réelle (inscrits → présents) | > 60% |
| **Rétention** | Créateurs récurrents (≥ 2 événements) | > 30% |
| **Satisfaction** | Note moyenne post-événement | ≥ 4.0/5 |

### 5. Métriques de succès (par phase)

#### MVP (maintenant)
- ✅ Un membre peut créer un événement
- ✅ Un membre peut voir la liste des événements
- ✅ Un membre peut RSVP / se désinscrire
- ✅ Les RSVP sont persistés en base et affichés

#### V2 (prochain palier)
- 📍 Découverte géolocalisée (événements près de chez moi)
- 📸 Galerie photo post-événement
- 👥 Liste des participants visible
- 🔔 Rappels 24h avant

#### V3 (ambition)
- 🎟️ Billetterie payante (Stripe/Mobile Money)
- 💬 Groupe de discussion privé par événement
- 🔴 Live streaming / replay vidéo
- 🤝 Matching networking intelligent

### 6. Personas

| Persona | Âge | Localisation | Rôle | Besoin clé |
|---------|-----|-------------|------|------------|
| **Aïssatou** | 32 | Paris, France | Organisatrice (meetups pros) | Centraliser WhatsApp + Google Forms + Eventbrite |
| **Moussa** | 25 | Dakar, Sénégal | Participant occasionnel | Découvrir les événements à temps, voir qui y va |
| **Oumar** | 45 | New York, USA | Leader communautaire (festival 300+) | Gérer inscriptions, paiements, bénévoles |

---

## Phase 1 — Recherche & Benchmark

### Tableau comparatif des plateformes

| Plateforme | Différenciateur | Top 3 UX (mobile) | Faiblesses |
|-----------|----------------|-------------------|------------|
| **Partiful** | RSVP par SMS, social-first | 1. RSVP 1-clic 2. Feed photo partagé 3. Blast SMS | Design juvénile, limité en pro |
| **Luma** | CRM + communautés intégrées | 1. Segmentation invités 2. Chat événement 3. Landing pages | Fonctionnalités payantes |
| **Eventbrite** | Marketplace massive | 1. Marque de confiance 2. Check-in physique 3. Base utilisateurs | Frais élevés, impersonnel |
| **Meetup** | Découverte communautaire | 1. Groupes locaux 2. Alertes niche 3. Récurrence | Interface datée, friction organisateur |
| **Facebook** | Ubiquité, viralité | 1. Familiarité 2. Intégration sociale 3. Partage facile | Vie privée, notifications polluées |

### Top 5 fonctionnalités empruntées

1. **RSVP text-first (Partiful)** — lien partageable WhatsApp/Telegram, pas besoin d'app
2. **CRM communautaire (Luma)** — export liste participants, suivi des habitués
3. **Communication blast temps réel (Partiful)** — notif push/SMS aux inscrits
4. **Feed social pré-événement (Luma/Partiful)** — les inscrits se présentent avant
5. **Collecte simplifiée (Partiful)** — contributions (repas, paiements) dans le flux RSVP

### Principes UX retenus

- **Règle des 3 étapes** pour l'inscription (identité → sélection → finalisation)
- **Profilage progressif** — ne pas tout demander upfront
- **Micro-engagement pré-événement** — sondages, questions, matchmaking
- **Hub de contenu post-événement** — replays, galeries, forum
- **Offline-first** pour le check-in sur site (cache local)

---

## Phase 3 — Inventaire des Fonctionnalités

### Matrice de priorisation

| # | Fonctionnalité | Importance | Complexité | Phase | Statut |
|---|---------------|-----------|-----------|-------|--------|
| F1 | Liste des événements avec filtres | ⭐⭐⭐⭐⭐ | Basse | MVP | ✅ |
| F2 | Création d'événement | ⭐⭐⭐⭐⭐ | Basse | MVP | ✅ |
| F3 | RSVP / désinscription (1 clic) | ⭐⭐⭐⭐⭐ | Basse | MVP | ✅ |
| F4 | FAB "+" création événement | ⭐⭐⭐⭐ | Basse | MVP | ✅ |
| F5 | Écran détail événement | ⭐⭐⭐⭐⭐ | Moyenne | MVP | ✅ |
| F6 | Liste des participants (preview) | ⭐⭐⭐⭐ | Basse | MVP | ✅ |
| F7 | Mes événements (Créés + Rejoints) | ⭐⭐⭐⭐ | Moyenne | MVP | ✅ |
| F8 | Ticket/QR code post-RSVP | ⭐⭐⭐ | Basse | MVP | ✅ |
| F9 | Upload image événement | ⭐⭐⭐ | Moyenne | MVP | ❌ |
| F10 | Notification 24h avant événement | ⭐⭐⭐⭐ | Moyenne | V2 | ❌ |
| F11 | Découverte géolocalisée | ⭐⭐⭐⭐ | Haute | V2 | ❌ |
| F12 | Groupe discussion privé par événement | ⭐⭐⭐⭐ | Haute | V2 | ❌ |
| F13 | Galerie photo post-événement | ⭐⭐⭐ | Moyenne | V2 | ❌ |
| F14 | Check-in QR code réel | ⭐⭐⭐ | Haute | V3 | ❌ |
| F15 | Billetterie payante (Stripe) | ⭐⭐⭐ | Très haute | V3 | ❌ |
| F16 | Networking matching intelligent | ⭐⭐ | Très haute | V3 | ❌ |
| F17 | Live streaming / replay vidéo | ⭐⭐ | Très haute | V3 | ❌ |

---

## Phase 4 — Architecture UX (Écrans)

### Sitemap du module Événements

```
Événements (MainShell tab)
│
├── /events ─────────────────── Liste (events_screen.dart) ✅
│   ├── [FAB +] ─────────────── Création (create_event_screen.dart) ✅
│   └── [Carte] ─────────────── Détail (event_detail_screen.dart) ✅
│       ├── [S'inscrire] ─────── RSVP (toggleRsvp) ✅
│       ├── [Participants] ──── Liste des inscrits ✅
│       └── [Groupe] ────────── Chat privé événement ❌ V2
│
├── /my-events ──────────────── Mes événements (my_events_screen.dart) ✅
│   ├── Onglet "Créés"
│   └── Onglet "Rejoints"
│
└── /event-check-in ─────────── Scanner QR code ❌ V3
```

### Écran 1 : Liste `/events` — ✅

**Fichier :** `lib/features/events/events_screen.dart`

- Header + SearchBar + Chips catégorie
- Liste de EventCard avec image, titre, date, lieu, RSVP
- FAB "+" → CreateEventScreen
- Clic carte → EventDetailScreen

### Écran 2 : Création `/create-event` — ✅

**Fichier :** `lib/features/events/create_event_screen.dart`

- Formulaire : Titre*, Date/Heure*, Lieu*, Catégorie (chips), Description
- Design d'input unifié (Material + shape + ClipRRect)
- Astérisques rouges sur champs obligatoires
- Succès → invalidation eventsProvider → retour

### Écran 3 : Détail `/event-detail?{id}` — ✅

**Fichier :** `lib/features/events/event_detail_screen.dart`

- SliverAppBar avec hero image + gradient
- Category badge, titre, info cards (date, lieu, participants)
- Description complète
- Preview participants (avatars, compteur)
- Bouton RSVP / Désinscription

### Écran 4 : Mes Événements `/my-events` — ✅

**Fichier :** `lib/features/events/my_events_screen.dart`

- TabBar : Créés | Rejoints
- Tri : à venir → passés, badge "PASSÉ"
- Mini cartes avec date, participants, catégorie
- État vide + bouton "Créer un événement" (onglet Créés)
- Gestion d'erreur avec retry

---

## État des lieux du code

### Base de données (Supabase)

| Composant | Statut |
|-----------|--------|
| Table `events` (10 colonnes) | ✅ |
| Table `event_rsvps` (FK events + members) | ✅ |
| Trigger `tg_event_rsvp_count` | ✅ |

### Backend (Dart)

| Composant | Statut | Fichier |
|-----------|--------|---------|
| Modèle `Event` | ✅ | `lib/core/data/models/event.dart` |
| `EventsRepository.fetchAll()` | ✅ | `lib/core/data/repositories/events_repository.dart` |
| `EventsRepository.fetchUserRsvpIds()` | ✅ | |
| `EventsRepository.toggleRsvp()` | ✅ | |
| `EventsRepository.createEvent()` | ✅ | |
| `EventsRepository.fetchById()` | ✅ | |
| `EventsRepository.fetchAttendees()` | ✅ | |
| `EventsRepository.fetchMyCreatedEventIds()` | ✅ | |
| `EventsRepository.fetchMyRsvpEventIds()` | ✅ | |
| Provider `eventsProvider` | ✅ | `lib/core/data/providers/data_providers.dart` |

### Frontend (Flutter)

| Écran | Statut | Fichier |
|-------|--------|---------|
| Liste + filtres | ✅ | `lib/features/events/events_screen.dart` |
| Création | ✅ | `lib/features/events/create_event_screen.dart` |
| Détail | ✅ | `lib/features/events/event_detail_screen.dart` |
| Mes événements | ✅ | `lib/features/events/my_events_screen.dart` |
| Routes | ✅ | `/events`, `/create-event`, `/event-detail`, `/my-events` |

---

## Priorités immédiates

| # | Tâche | Effort |
|---|-------|--------|
| 1 | Upload image dans `CreateEventScreen` (pattern `image_picker` existant) | 30 min |
| 2 | Lien d'accès vers `/my-events` depuis `events_screen.dart` | 5 min |
| 3 | Notification 24h avant événement (V2) | 2h |
| 4 | Découverte géolocalisée (V2) | 4h |

---

> **Prochaine session :** Continuer avec la roadmap V2 (notifications, géolocalisation) ou selon les priorités du Product Owner.
