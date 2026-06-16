-- =============================================================================
-- Fulɓe Connect — DEV RESET (⚠️  DESTRUCTIVE)
-- =============================================================================
-- Date    : 2026-06-09
-- Purpose : Wipe ALL Fulɓe Connect objects (tables, views, functions, triggers)
--           so 001_init_schema.sql can recreate them cleanly.
--
-- ⚠️  NEVER run this in production. ALL DATA WILL BE LOST.
--
-- When to run:
--   * Before the first apply (clean slate)
--   * After a partial/messy apply (idempotent fix)
--   * When a migration fails with "column X does not exist" (schema drift)
--
-- Order:
--   1. Run this file FIRST in the Supabase SQL Editor
--   2. Then run 20260609_001_init_schema.sql
--   3. Then 20260609_002_rls_policies.sql
--   4. Then 20260609_003_seed_dev_data.sql
--   5. Then 20260609_004_functions_triggers.sql
-- =============================================================================

-- Safety prompt: a NOTICE tells the user this is destructive.
do $$
begin
  raise notice '⚠️  DEV RESET — dropping all Fulɓe Connect objects';
  raise notice 'Tables, views, functions, triggers, and policies will be removed.';
end $$;

-- Drop in reverse FK-dependency order (children first, parents last).
-- CASCADE removes dependent objects (triggers, policies, indexes).
drop table if exists public.event_rsvps          cascade;
drop table if exists public.transactions         cascade;
drop table if exists public.subscriptions        cascade;
drop table if exists public.posts                cascade;
drop table if exists public.events               cascade;
drop table if exists public.jobs                 cascade;
drop table if exists public.marketplace_services cascade;
drop table if exists public.announcements        cascade;
drop table if exists public.books                cascade;
drop table if exists public.community_projects   cascade;
drop table if exists public.member_follows       cascade;
drop table if exists public.member_skills        cascade;
drop table if exists public.member_clusters      cascade;
drop table if exists public.members              cascade;

-- Drop views (in case they exist from a previous run of 004).
drop view if exists public.v_member_profiles     cascade;
drop view if exists public.v_event_popularity    cascade;
drop view if exists public.v_home_feed           cascade;
drop view if exists public.v_user_finances       cascade;

-- Drop helper functions (in case they exist from a previous run of 004).
drop function if exists public.tg_set_updated_at()      cascade;
drop function if exists public.tg_event_rsvp_count()    cascade;
drop function if exists public.tg_handle_new_user()     cascade;
drop function if exists public.hex_to_color(text)       cascade;
drop function if exists public.uid()                    cascade;
drop function if exists public.is_admin()               cascade;

-- Drop the auth.users trigger we created in 004 (so 004 can recreate it).
drop trigger if exists on_auth_user_created on auth.users cascade;

-- Re-grant default privileges (in case we accidentally revoked them).
grant usage on schema public to anon, authenticated;
grant select on all tables in schema public to anon, authenticated;

do $$
begin
  raise notice '✅  Drop complete. You can now run 001_init_schema.sql';
end $$;
