# Réseau d'Associations Fulɓe — Design

**Date** : 2026-06-09
**Statut** : ✅ Validé

## Contexte

La diaspora Peule (Fulɓe) est organisée en **associations locales** structurées de manière hiérarchique :

- **Association parente** (ex. *Dental Fulbe Italia*) — couvre un pays
- **Branches locales** (ex. *Dental Fulbe Vicenza*, *Dental Fulbe Milano*) — une par ville

Objectif produit : permettre à un membre d'être **automatiquement catégorisé** dans sa branche et son association parente, simplement à partir de son **pays + ville** déclarés à l'inscription, sans action manuelle.

## Décisions produit (validées)

| Question | Décision |
|---|---|
| Adhésion | **Auto-détection** via pays + ville du profil |
| Source de vérité | **Hybride** : grandes assos pre-seedées + petites via self-serve |
| Écrans concernés | **Tous** : badge profil + filtre annuaire + fil dédié + pins World Map |

## Modèle de données

### 3 nouvelles tables

```sql
-- Associations parentes (pays)
CREATE TABLE public.organizations (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  country      TEXT NOT NULL,
  description  TEXT,
  status       TEXT NOT NULL DEFAULT 'active'
                 CHECK (status IN ('active', 'pending')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (name, country)
);

-- Branches locales (ville)
CREATE TABLE public.chapters (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  city            TEXT NOT NULL,
  description     TEXT,
  status          TEXT NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active', 'pending')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, city)
);

-- Extension de members (FK dénormalisées, auto-populées)
ALTER TABLE public.members
  ADD COLUMN organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
  ADD COLUMN chapter_id       UUID REFERENCES public.chapters(id)       ON DELETE SET NULL;
```

### Trigger d'auto-détection

```sql
CREATE OR REPLACE FUNCTION public.match_member_to_chapter()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_chapter_id       UUID;
  v_organization_id  UUID;
BEGIN
  -- Cherche un chapitre actif dont (country, city) matche le profil
  SELECT c.id, c.organization_id
    INTO v_chapter_id, v_organization_id
    FROM public.chapters c
    JOIN public.organizations o ON o.id = c.organization_id
   WHERE o.country = NEW.country
     AND c.city    = NEW.city
     AND c.status  = 'active'
     AND o.status  = 'active'
   LIMIT 1;

  NEW.chapter_id       := v_chapter_id;
  NEW.organization_id  := v_organization_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_match_member_to_chapter
  BEFORE INSERT OR UPDATE OF country, city ON public.members
  FOR EACH ROW EXECUTE FUNCTION public.match_member_to_chapter();
```

### RLS

- Lecture `organizations` / `chapters` : tout le monde pour `status='active'`
- Insertion en `status='pending'` : n'importe quel membre authentifié
- Update `status='active'` : admin uniquement (via policy `is_admin`)

## UX dans les 4 écrans

| Écran | Affichage | Action |
|---|---|---|
| **Profile** | Badge `Membre de Dental Fulbe Vicenza` sous le nom | Tap → page chapitre |
| **Directory** | Chip `Mon association` (toggle dans la barre de filtres) | Filtre `chapter_id = currentUser.chapterId` |
| **World Map** | Pin par chapitre (coloré par assos parente) | Tap → page chapitre |
| **Fil dédié** *(nouveau)* | `_ChapterDetailScreen` : posts + events + membres du chapitre | Tab interne : Posts / Événements / Membres |

## Pre-seed (exemples)

```sql
-- Italie
INSERT INTO organizations (name, country) VALUES ('Dental Fulbe Italia', 'Italie');
INSERT INTO chapters (organization_id, name, city) VALUES
  ((SELECT id FROM organizations WHERE name='Dental Fulbe Italia'), 'Dental Fulbe Vicenza', 'Vicenza'),
  ((SELECT id FROM organizations WHERE name='Dental Fulbe Italia'), 'Dental Fulbe Milano', 'Milan'),
  ((SELECT id FROM organizations WHERE name='Dental Fulbe Italia'), 'Dental Fulbe Roma', 'Rome'),
  ((SELECT id FROM organizations WHERE name='Dental Fulbe Italia'), 'Dental Fulbe Napoli', 'Naples'),
  ((SELECT id FROM organizations WHERE name='Dental Fulbe Italia'), 'Dental Fulbe Torino', 'Turin');

-- France
INSERT INTO organizations (name, country) VALUES ('Confédération Fulɓe France', 'France');
INSERT INTO chapters (organization_id, name, city) VALUES
  ((SELECT id FROM organizations WHERE name='Confédération Fulɓe France'), 'CFF Île-de-France', 'Paris'),
  ((SELECT id FROM organizations WHERE name='Confédération Fulɓe France'), 'CFF PACA', 'Marseille'),
  ((SELECT id FROM organizations WHERE name='Confédération Fulɓe France'), 'CFF Lyon', 'Lyon'),
  ((SELECT id FROM organizations WHERE name='Confédération Fulɓe France'), 'CFF Bordeaux', 'Bordeaux');
```

## Self-serve

- Bouton « Proposer une association » dans le profil (visible si `organization_id IS NULL`)
- Formulaire : nom + pays + ville + description → insert `status='pending'`
- Vue admin (à venir, hors scope) pour valider

## Fichiers à créer / modifier

**DB (nouveaux)**
- `supabase/migrations/20260609_005_orgs_chapters.sql`
- `supabase/migrations/20260609_006_seed_organizations.sql`

**Code (nouveaux)**
- `lib/core/data/models/organization.dart`
- `lib/core/data/models/chapter.dart`
- `lib/core/data/repositories/organizations_repository.dart`
- `lib/core/data/providers/organizations_providers.dart` (3 providers)

**UI (nouveaux)**
- `lib/features/chapter/chapter_detail_screen.dart`
- `lib/features/chapter/widgets/chapter_badge.dart`

**UI (modifications)**
- `lib/features/profile/profile_screen.dart` : badge + lien
- `lib/features/directory/directory_screen.dart` : chip `Mon association`
- `lib/features/map/world_map_screen.dart` : pins par chapitre
- `lib/core/data/providers/data_providers.dart` : 3 nouveaux providers
- `lib/core/navigation/app_router.dart` : route `chapterDetail`

## Estimation

| Phase | Durée |
|---|---|
| DB (2 migrations + seed) | 1h |
| Modèles + repository + providers | 1h30 |
| Badge + filtre annuaire | 1h |
| Pins World Map | 1h30 |
| `_ChapterDetailScreen` (posts/events/members) | 2h |
| Tests | 1h |
| **Total** | **~8h** |

## Hors scope (V1)

- Workflow d'approbation admin (insert `status='pending'` OK, validation manuelle côté Supabase Dashboard)
- Page admin dédiée
- Multi-appartenance (un membre dans plusieurs chapitres)
- Chapitres régionaux (niveau sous-ville)
