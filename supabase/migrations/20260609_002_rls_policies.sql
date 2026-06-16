-- =============================================================================
-- Fulɓe Connect — Row Level Security (RLS) Policies
-- =============================================================================
-- Date    : 2026-06-09
-- Purpose : Enable RLS and define access policies for all tables.
-- Order   : 2/4 (run AFTER 001_init_schema)
--
-- Best practices applied (per supabase-postgres-best-practices):
--   * security-rls-basics      : enable RLS on every table
--   * security-privileges      : revoke default privileges, grant minimally
--   * security-rls-performance : scope auth.uid() checks via subquery (select auth.uid())
--     to enable initplan caching
--
-- Access matrix:
--   - members           : SELECT public; INSERT/UPDATE/DELETE for owner only
--   - member_skills     : SELECT public; ALL for owner of the parent member
--   - member_clusters   : SELECT public; mutations admin-only
--   - posts             : SELECT public; INSERT for any authed; UPDATE/DELETE owner
--   - announcements     : SELECT public; mutations admin-only
--   - events            : SELECT public; INSERT authed; UPDATE/DELETE owner
--   - event_rsvps       : SELECT public; INSERT/DELETE for self only
--   - jobs              : SELECT public; mutations admin or poster
--   - marketplace_services : SELECT public; mutations for provider
--   - books             : SELECT public; read-only (admin-curated)
--   - transactions      : SELECT for owner; mutations admin
--   - community_projects: SELECT public; mutations admin
--   - subscriptions     : SELECT for owner; mutations admin
-- =============================================================================

-- =============================================================================
-- Helpers: tiny functions used by RLS policies to enable initplan caching.
-- Wrapping `auth.uid()` in a (select ...) makes the planner evaluate it once
-- per query instead of per row.
-- =============================================================================
create or replace function public.uid() returns uuid
  language sql stable
  as $$
    select auth.uid()
  $$;

create or replace function public.is_admin() returns boolean
  language sql stable
  as $$
    select coalesce(
      (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin',
      false
    )
  $$;

-- =============================================================================
-- members
-- =============================================================================
alter table public.members enable row level security;

drop policy if exists "members_select_public" on public.members;
create policy "members_select_public"
  on public.members for select
  using (true);

drop policy if exists "members_insert_self" on public.members;
create policy "members_insert_self"
  on public.members for insert
  with check ((select auth.uid()) = user_id);

drop policy if exists "members_update_self" on public.members;
create policy "members_update_self"
  on public.members for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "members_delete_self" on public.members;
create policy "members_delete_self"
  on public.members for delete
  using ((select auth.uid()) = user_id or public.is_admin());

-- =============================================================================
-- member_skills
-- =============================================================================
alter table public.member_skills enable row level security;

drop policy if exists "member_skills_select_public" on public.member_skills;
create policy "member_skills_select_public"
  on public.member_skills for select
  using (true);

drop policy if exists "member_skills_modify_self" on public.member_skills;
create policy "member_skills_modify_self"
  on public.member_skills for all
  using (
    exists (
      select 1 from public.members m
      where m.id = member_skills.member_id
        and m.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.members m
      where m.id = member_skills.member_id
        and m.user_id = (select auth.uid())
    )
  );

-- =============================================================================
-- member_clusters (read-only for users, admin for mutations)
-- =============================================================================
alter table public.member_clusters enable row level security;

drop policy if exists "member_clusters_select_public" on public.member_clusters;
create policy "member_clusters_select_public"
  on public.member_clusters for select
  using (true);

drop policy if exists "member_clusters_modify_admin" on public.member_clusters;
create policy "member_clusters_modify_admin"
  on public.member_clusters for all
  using (public.is_admin())
  with check (public.is_admin());

-- =============================================================================
-- posts
-- =============================================================================
alter table public.posts enable row level security;

drop policy if exists "posts_select_public" on public.posts;
create policy "posts_select_public"
  on public.posts for select
  using (true);

drop policy if exists "posts_insert_authed" on public.posts;
create policy "posts_insert_authed"
  on public.posts for insert
  with check (
    (select auth.uid()) is not null
    and exists (
      select 1 from public.members m
      where m.id = posts.author_id
        and m.user_id = (select auth.uid())
    )
  );

drop policy if exists "posts_update_owner" on public.posts;
create policy "posts_update_owner"
  on public.posts for update
  using (
    exists (
      select 1 from public.members m
      where m.id = posts.author_id
        and m.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.members m
      where m.id = posts.author_id
        and m.user_id = (select auth.uid())
    )
  );

drop policy if exists "posts_delete_owner" on public.posts;
create policy "posts_delete_owner"
  on public.posts for delete
  using (
    exists (
      select 1 from public.members m
      where m.id = posts.author_id
        and m.user_id = (select auth.uid())
    )
    or public.is_admin()
  );

-- =============================================================================
-- announcements
-- =============================================================================
alter table public.announcements enable row level security;

drop policy if exists "announcements_select_public" on public.announcements;
create policy "announcements_select_public"
  on public.announcements for select
  using (active = true or public.is_admin());

drop policy if exists "announcements_modify_admin" on public.announcements;
create policy "announcements_modify_admin"
  on public.announcements for all
  using (public.is_admin())
  with check (public.is_admin());

-- =============================================================================
-- events
-- =============================================================================
alter table public.events enable row level security;

drop policy if exists "events_select_public" on public.events;
create policy "events_select_public"
  on public.events for select
  using (true);

drop policy if exists "events_insert_authed" on public.events;
create policy "events_insert_authed"
  on public.events for insert
  with check ((select auth.uid()) is not null);

drop policy if exists "events_modify_owner" on public.events;
create policy "events_modify_owner"
  on public.events for update
  using (public.is_admin() or (select auth.uid()) = created_by)
  with check (public.is_admin() or (select auth.uid()) = created_by);

drop policy if exists "events_delete_owner" on public.events;
create policy "events_delete_owner"
  on public.events for delete
  using (public.is_admin() or (select auth.uid()) = created_by);

-- =============================================================================
-- event_rsvps
-- =============================================================================
alter table public.event_rsvps enable row level security;

drop policy if exists "event_rsvps_select_public" on public.event_rsvps;
create policy "event_rsvps_select_public"
  on public.event_rsvps for select
  using (true);

drop policy if exists "event_rsvps_insert_self" on public.event_rsvps;
create policy "event_rsvps_insert_self"
  on public.event_rsvps for insert
  with check (
    exists (
      select 1 from public.members m
      where m.id = event_rsvps.user_id
        and m.user_id = (select auth.uid())
    )
  );

drop policy if exists "event_rsvps_delete_self" on public.event_rsvps;
create policy "event_rsvps_delete_self"
  on public.event_rsvps for delete
  using (
    exists (
      select 1 from public.members m
      where m.id = event_rsvps.user_id
        and m.user_id = (select auth.uid())
    )
  );

-- =============================================================================
-- jobs
-- =============================================================================
alter table public.jobs enable row level security;

drop policy if exists "jobs_select_public" on public.jobs;
create policy "jobs_select_public"
  on public.jobs for select
  using (active = true or public.is_admin());

drop policy if exists "jobs_insert_authed" on public.jobs;
create policy "jobs_insert_authed"
  on public.jobs for insert
  with check ((select auth.uid()) is not null);

drop policy if exists "jobs_modify_owner" on public.jobs;
create policy "jobs_modify_owner"
  on public.jobs for update
  using (public.is_admin() or (select auth.uid()) = posted_by)
  with check (public.is_admin() or (select auth.uid()) = posted_by);

drop policy if exists "jobs_delete_owner" on public.jobs;
create policy "jobs_delete_owner"
  on public.jobs for delete
  using (public.is_admin() or (select auth.uid()) = posted_by);

-- =============================================================================
-- marketplace_services
-- =============================================================================
alter table public.marketplace_services enable row level security;

drop policy if exists "marketplace_services_select_public" on public.marketplace_services;
create policy "marketplace_services_select_public"
  on public.marketplace_services for select
  using (active = true or public.is_admin());

drop policy if exists "marketplace_services_insert_authed" on public.marketplace_services;
create policy "marketplace_services_insert_authed"
  on public.marketplace_services for insert
  with check ((select auth.uid()) is not null);

drop policy if exists "marketplace_services_modify_owner" on public.marketplace_services;
create policy "marketplace_services_modify_owner"
  on public.marketplace_services for update
  using (public.is_admin() or (select auth.uid()) = provider_id)
  with check (public.is_admin() or (select auth.uid()) = provider_id);

drop policy if exists "marketplace_services_delete_owner" on public.marketplace_services;
create policy "marketplace_services_delete_owner"
  on public.marketplace_services for delete
  using (public.is_admin() or (select auth.uid()) = provider_id);

-- =============================================================================
-- books (read-only for users, admin manages catalog)
-- =============================================================================
alter table public.books enable row level security;

drop policy if exists "books_select_public" on public.books;
create policy "books_select_public"
  on public.books for select
  using (active = true or public.is_admin());

drop policy if exists "books_modify_admin" on public.books;
create policy "books_modify_admin"
  on public.books for all
  using (public.is_admin())
  with check (public.is_admin());

-- =============================================================================
-- transactions
-- =============================================================================
alter table public.transactions enable row level security;

drop policy if exists "transactions_select_self" on public.transactions;
create policy "transactions_select_self"
  on public.transactions for select
  using (
    exists (
      select 1 from public.members m
      where m.id = transactions.user_id
        and m.user_id = (select auth.uid())
    )
    or public.is_admin()
  );

drop policy if exists "transactions_modify_admin" on public.transactions;
create policy "transactions_modify_admin"
  on public.transactions for all
  using (public.is_admin())
  with check (public.is_admin());

-- =============================================================================
-- community_projects (read-only for users, admin manages)
-- =============================================================================
alter table public.community_projects enable row level security;

drop policy if exists "community_projects_select_public" on public.community_projects;
create policy "community_projects_select_public"
  on public.community_projects for select
  using (active = true or public.is_admin());

drop policy if exists "community_projects_modify_admin" on public.community_projects;
create policy "community_projects_modify_admin"
  on public.community_projects for all
  using (public.is_admin())
  with check (public.is_admin());

-- =============================================================================
-- subscriptions
-- =============================================================================
alter table public.subscriptions enable row level security;

drop policy if exists "subscriptions_select_self" on public.subscriptions;
create policy "subscriptions_select_self"
  on public.subscriptions for select
  using (
    exists (
      select 1 from public.members m
      where m.id = subscriptions.user_id
        and m.user_id = (select auth.uid())
    )
    or public.is_admin()
  );

drop policy if exists "subscriptions_modify_admin" on public.subscriptions;
create policy "subscriptions_modify_admin"
  on public.subscriptions for all
  using (public.is_admin())
  with check (public.is_admin());

-- =============================================================================
-- Default privilege hardening
-- =============================================================================
-- Revoke broad default privileges on these tables from anonymous/authenticated
-- roles, then grant only what's needed. The policies above define row-level
-- access; these grants define table-level access.
-- =============================================================================
revoke all on all tables in schema public from anon, authenticated;

grant usage on schema public to anon, authenticated;

grant select on all tables in schema public to anon;
grant select on all tables in schema public to authenticated;

-- Authenticated users get write access on their own data (enforced by RLS).
grant insert, update, delete on
  public.members,
  public.member_skills,
  public.posts,
  public.events,
  public.event_rsvps,
  public.jobs,
  public.marketplace_services
  to authenticated;
