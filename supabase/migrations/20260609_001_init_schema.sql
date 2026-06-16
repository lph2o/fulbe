-- =============================================================================
-- Fulɓe Connect — Initial Schema
-- =============================================================================
-- Date    : 2026-06-09
-- Purpose : Create all core tables for the community platform.
-- Order   : 1/4 (run before rls_policies, seed_dev_data, functions_triggers)
--
-- Best practices applied (per supabase-postgres-best-practices):
--   * schema-lowercase-identifiers : all tables/columns in snake_case
--   * schema-primary-keys          : UUID primary keys with gen_random_uuid()
--   * schema-foreign-key-indexes   : index on every FK column
--   * schema-constraints           : NOT NULL where it makes sense
--   * schema-data-types            : timestamptz (not timestamp) for all dates
-- =============================================================================

-- =============================================================================
-- ⚠️  DEV-ONLY: Drop all Fulɓe Connect objects before recreating
-- =============================================================================
-- Set the session variable below to 'dev' to enable destructive drops.
-- In production, leave it unset or set to 'prod' (the block is a no-op).
--
--   psql ... -v fulbe_env=dev     -f 001_init_schema.sql   (DEV: drops + recreates)
--   psql ... -v fulbe_env=prod    -f 001_init_schema.sql   (PROD: only creates if missing)
--   Supabase Dashboard: no variable → defaults to 'prod' (safe)
-- =============================================================================
do $$
begin
  if coalesce(current_setting('fulbe_env', true), 'prod') = 'dev' then
    raise notice 'fulbe_env=dev → dropping all Fulɓe Connect objects for clean re-apply';

    -- Drop in reverse FK-dependency order (children first, parents last).
    -- CASCADE removes dependent objects (triggers, policies, indexes).
    drop table if exists public.event_rsvps        cascade;
    drop table if exists public.transactions       cascade;
    drop table if exists public.subscriptions      cascade;
    drop table if exists public.posts              cascade;
    drop table if exists public.events             cascade;
    drop table if exists public.jobs               cascade;
    drop table if exists public.marketplace_services cascade;
    drop table if exists public.announcements      cascade;
    drop table if exists public.books              cascade;
    drop table if exists public.community_projects cascade;
    drop table if exists public.member_follows     cascade;
    drop table if exists public.member_skills      cascade;
    drop table if exists public.member_clusters    cascade;
    drop table if exists public.members            cascade;

    -- Drop views (in case they exist from a previous run of 004).
    drop view  if exists public.v_member_profiles  cascade;
    drop view  if exists public.v_event_popularity cascade;
    drop view  if exists public.v_home_feed        cascade;
    drop view  if exists public.v_user_finances    cascade;

    -- Drop helper functions (in case they exist from a previous run of 004).
    drop function if exists public.tg_set_updated_at()      cascade;
    drop function if exists public.tg_event_rsvp_count()    cascade;
    drop function if exists public.tg_handle_new_user()     cascade;
    drop function if exists public.hex_to_color(text)       cascade;
    drop function if exists public.uid()                    cascade;
    drop function if exists public.is_admin()               cascade;
  else
    raise notice 'fulbe_env=prod (or unset) → preserving existing objects';
  end if;
end $$;

-- Required extensions
create extension if not exists "pgcrypto";     -- gen_random_uuid()
create extension if not exists "uuid-ossp";     -- fallback uuid generator

-- =============================================================================
-- 1. members
-- =============================================================================
create table if not exists public.members (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid unique references auth.users(id) on delete cascade,
  full_name       text not null,
  profession      text not null,
  city            text not null,
  country         text not null,
  avatar_url      text,
  initials        text,
  is_verified     boolean not null default false,
  linkedin        text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_members_user_id   on public.members(user_id);
create index if not exists idx_members_country  on public.members(country);
create index if not exists idx_members_profession on public.members(profession);
create index if not exists idx_members_city      on public.members(city);

-- =============================================================================
-- 2. member_skills (1-to-many from members)
-- =============================================================================
create table if not exists public.member_skills (
  id         uuid primary key default gen_random_uuid(),
  member_id  uuid not null references public.members(id) on delete cascade,
  skill      text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_member_skills_member_id on public.member_skills(member_id);
create index if not exists idx_member_skills_skill     on public.member_skills(skill);

-- =============================================================================
-- 3. member_clusters (geographic clusters for world map)
-- =============================================================================
create table if not exists public.member_clusters (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  country    text not null,
  count      integer not null default 0,
  lat_pct    double precision not null check (lat_pct between 0 and 1),
  lng_pct    double precision not null check (lng_pct between 0 and 1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_member_clusters_country on public.member_clusters(country);

-- =============================================================================
-- 4. posts (home feed)
-- =============================================================================
create table if not exists public.posts (
  id             uuid primary key default gen_random_uuid(),
  author_id      uuid not null references public.members(id) on delete cascade,
  content        text not null,
  image_url      text,
  likes_count    integer not null default 0,
  comments_count integer not null default 0,
  time_ago       text not null default '',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists idx_posts_author_id  on public.posts(author_id);
create index if not exists idx_posts_created_at on public.posts(created_at desc);

-- =============================================================================
-- 5. announcements (community announcements on home feed)
-- =============================================================================
create table if not exists public.announcements (
  id          uuid primary key default gen_random_uuid(),
  chip_label  text not null,
  chip_icon   text not null default 'event',
  title       text not null,
  description text not null,
  cta_label   text not null,
  cta_route   text,
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists idx_announcements_active on public.announcements(active);

-- =============================================================================
-- 6. events
-- =============================================================================
create table if not exists public.events (
  id              uuid primary key default gen_random_uuid(),
  title           text not null,
  date            timestamptz not null,
  location        text not null,
  category        text not null,
  description     text not null,
  image_url       text not null default '',
  attendee_count  integer not null default 0,
  created_by      uuid references public.members(id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_events_date      on public.events(date);
create index if not exists idx_events_category  on public.events(category);
create index if not exists idx_events_created_by on public.events(created_by);

-- =============================================================================
-- 7. event_rsvps (RSVP table for events)
-- =============================================================================
create table if not exists public.event_rsvps (
  id         uuid primary key default gen_random_uuid(),
  event_id   uuid not null references public.events(id) on delete cascade,
  user_id    uuid not null references public.members(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (event_id, user_id)
);

create index if not exists idx_event_rsvps_event_id on public.event_rsvps(event_id);
create index if not exists idx_event_rsvps_user_id  on public.event_rsvps(user_id);

-- =============================================================================
-- 8. jobs
-- =============================================================================
create table if not exists public.jobs (
  id                uuid primary key default gen_random_uuid(),
  title             text not null,
  company           text not null,
  company_logo_url  text,
  company_initials  text,
  location          text not null,
  type              text not null,  -- Full-time, Contract, Internship, Mission Freelance
  domain            text not null,  -- Tech, Agriculture, Santé, Finance, Design
  posted_ago        text not null default '',
  badge             text,
  badge_type        text,           -- 'alumni', 'partner', 'student'
  posted_by         uuid references public.members(id) on delete set null,
  active            boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists idx_jobs_active     on public.jobs(active);
create index if not exists idx_jobs_type       on public.jobs(type);
create index if not exists idx_jobs_domain     on public.jobs(domain);
create index if not exists idx_jobs_location   on public.jobs(location);
create index if not exists idx_jobs_posted_by  on public.jobs(posted_by);

-- =============================================================================
-- 9. marketplace_services
-- =============================================================================
create table if not exists public.marketplace_services (
  id            uuid primary key default gen_random_uuid(),
  category      text not null,
  category_icon text not null default 'label',
  title         text not null,
  description   text not null,
  rating        double precision not null default 0.0 check (rating between 0 and 5),
  review_count  integer not null default 0,
  price         text not null,
  price_label   text not null default '',
  cta_label     text not null default 'Réserver',
  image_url     text,
  provider_id   uuid references public.members(id) on delete set null,
  active        boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists idx_marketplace_services_category on public.marketplace_services(category);
create index if not exists idx_marketplace_services_active   on public.marketplace_services(active);
create index if not exists idx_marketplace_services_provider on public.marketplace_services(provider_id);

-- =============================================================================
-- 10. books (cultural library)
-- =============================================================================
create table if not exists public.books (
  id              uuid primary key default gen_random_uuid(),
  title           text not null,
  author          text not null,
  emoji           text not null default '📖',
  color_hex       text not null default '#1B4332',
  category_index  integer not null default 0,
  active          boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_books_category_index on public.books(category_index);
create index if not exists idx_books_active          on public.books(active);

-- =============================================================================
-- 11. transactions (finances)
-- =============================================================================
create table if not exists public.transactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.members(id) on delete cascade,
  label       text not null,
  date        text not null,           -- free text (e.g. "10 Sept 2024 • Carte Bancaire")
  method      text not null,
  amount      double precision not null,  -- negative = debit, positive = credit
  icon        text not null default 'remove',
  occurred_at timestamptz not null default now(),
  created_at  timestamptz not null default now()
);

create index if not exists idx_transactions_user_id     on public.transactions(user_id);
create index if not exists idx_transactions_occurred_at on public.transactions(occurred_at desc);

-- =============================================================================
-- 12. community_projects (finances)
-- =============================================================================
create table if not exists public.community_projects (
  id              uuid primary key default gen_random_uuid(),
  title           text not null,
  location        text not null,
  icon            text not null default 'volunteer_activism',
  color           text not null default '#1B4332',
  current_amount  double precision not null default 0,
  target_amount   double precision not null,
  currency        text not null default 'FCFA',
  active          boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_community_projects_active on public.community_projects(active);

-- =============================================================================
-- 13. subscriptions (user subscription to the platform)
-- =============================================================================
create table if not exists public.subscriptions (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null unique references public.members(id) on delete cascade,
  plan          text not null default 'community',
  amount        double precision not null default 50.0,
  currency      text not null default 'FCFA',
  next_due_at   timestamptz,
  started_at    timestamptz not null default now(),
  cancelled_at  timestamptz
);

create index if not exists idx_subscriptions_user_id on public.subscriptions(user_id);
