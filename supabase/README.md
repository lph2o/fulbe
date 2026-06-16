# Fulɓe Connect — Supabase Migrations

This directory contains versioned SQL migrations for the Fulɓe Connect backend.
They should be applied in numerical order to a fresh Supabase project.

## 📁 Structure

| File | Purpose | Order |
|---|---|---|
| `000_dev_reset.sql` | ⚠️  **DESTRUCTIVE** — drops all Fulɓe Connect objects (run first in Dashboard) | 0/5 |
| `20260609_001_init_schema.sql` | 13 tables (members, posts, events, jobs, marketplace_services, books, transactions, community_projects, subscriptions, …) + indexes | 1/5 |
| `20260609_002_rls_policies.sql` | Row Level Security: enable on all tables + explicit policies + default privilege hardening | 2/5 |
| `20260609_003_seed_dev_data.sql` | Idempotent seed data (8 members, 5 clusters, 3 posts, 2 announcements, 5 events, 5 jobs, 4 services, 4 books, 4 transactions, 2 projects) | 3/5 |
| `20260609_004_functions_triggers.sql` | Auto-updated `updated_at`, RSVP counter, `tg_handle_new_user` (auto-create member on signup), 4 useful views, hex utility, Realtime enablement | 4/6 |
| `20260609_005_orgs_chapters.sql` | **Réseau d'Associations** : tables `organizations` + `chapters`, trigger `match_member_to_chapter` (auto-détection par `country`+`city`), RLS, Realtime | 5/6 |
| `20260609_006_seed_organizations.sql` | Pre-seed : **Dental Fulbe Italia** + 5 branches (Vicenza, Milano, Roma, Napoli, Torino), **Confédération Fulɓe France** + 4 branches, **Association Fulɓe Canada** + 2 branches | 6/6 |

## 🚀 How to apply

### Option A — Supabase CLI (recommended)

```bash
# From the project root
supabase link --project-ref <your-project-ref>
supabase db push                       # applies all pending migrations
```

### Option B — Supabase Dashboard SQL editor

Run each file in order in the **SQL Editor** of the Supabase dashboard:
1. Open https://app.supabase.com → your project → SQL Editor
2. Copy/paste each `.sql` file content, in numerical order
3. Click **Run** for each

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

## ✅ Verify after applying

```sql
-- Should return 13 rows
select count(*) from information_schema.tables
 where table_schema = 'public' and table_type = 'BASE TABLE';

-- Should return 13 rows (one per table)
select tablename, rowsecurity
  from pg_tables
 where schemaname = 'public';

-- Should return 5 events
select count(*) from public.events;

-- Should return 8 members
select count(*) from public.members;

-- Réseau d'Associations (Phase 1) : 3 organisations, 11 chapitres
select (select count(*) from public.organizations)         as orgs,
       (select count(*) from public.chapters)               as chapters,
       (select count(*) from public.members where chapter_id is not null) as members_matched;

-- Aperçu de la hiérarchie Italie
select o.name as organisation, c.city, c.name as chapter_name
  from public.chapters c
  join public.organizations o on o.id = c.organization_id
 where o.country = 'Italie'
 order by c.city;
```

## 🛡️ Security notes

- **All tables have RLS enabled.** Public anonymous users can only `SELECT` from the public-facing tables (members, posts, events, jobs, marketplace_services, books, community_projects, announcements).
- **Authenticated users** can additionally `INSERT`/`UPDATE`/`DELETE` their own data on `members`, `posts`, `events`, `event_rsvps`, `jobs`, `marketplace_services`.
- **Admin role** is detected via the `app_metadata.role = 'admin'` JWT claim. Promote a user with:
  ```sql
  update auth.users
     set raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}'::jsonb
   where id = '<user-uuid>';
  ```
- **`auth.users → public.members`** sync is automatic via the `tg_handle_new_user` trigger (set up in 004). User metadata `full_name`, `city`, `country`, `avatar_url` is propagated.

## 🔁 Reset (dev only)

```sql
-- Drop everything and re-apply from scratch
drop schema public cascade;
create schema public;
-- then re-grant default privileges
grant all on schema public to postgres, anon, authenticated, service_role;
-- re-run the 4 migration files
```

## 🧬 Schema overview

```
members ──┬── member_skills (1:N)
          └── transactions (1:N)
          └── subscriptions (1:1)

posts ──── (author_id → members.id)

events ──── (created_by → members.id)
   │
   └── event_rsvps (event_id, user_id)

jobs ────── (posted_by → members.id)
marketplace_services ── (provider_id → members.id)

member_clusters, announcements, books, community_projects ── (no FK to members, curated content)
```

## 🔗 Useful views

- `v_member_profiles` — members + their skills flattened as a `text[]` array
- `v_event_popularity` — events sorted by attendee_count
- `v_home_feed` — posts joined with author info
- `v_user_finances` — per-user balance + recent transactions + subscription
