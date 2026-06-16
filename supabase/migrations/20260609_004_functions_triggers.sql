-- =============================================================================
-- Fulɓe Connect — Functions, Triggers, and Views
-- =============================================================================
-- Date    : 2026-06-09
-- Purpose : Auto-maintain updated_at, aggregate event attendee counts, and
--           expose useful views for the Flutter app.
-- Order   : 4/4 (run AFTER 001_init_schema, 002_rls_policies, 003_seed_dev_data)
--
-- Best practices applied:
--   * data-n-plus-one      : views flatten joins, app issues 1 query instead of N
--   * schema-foreign-key-indexes : already indexed in 001
--   * trigger-pattern      : single reusable `tg_set_updated_at` function
-- =============================================================================

-- =============================================================================
-- 1. Generic updated_at trigger function
-- =============================================================================
-- Attaches to any table with an `updated_at timestamptz` column and bumps it
-- on every UPDATE.
create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Attach to every table that has an updated_at column.
do $$
declare
  t text;
begin
  for t in
    select c.table_name
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.column_name = 'updated_at'
  loop
    execute format(
      'drop trigger if exists trg_set_updated_at on public.%I;
       create trigger trg_set_updated_at
         before update on public.%I
         for each row execute function public.tg_set_updated_at();',
      t, t
    );
  end loop;
end $$;

-- =============================================================================
-- 2. Event attendee counter (auto-maintained)
-- =============================================================================
-- When a user RSVPs, increment events.attendee_count.
-- When they cancel, decrement (clamped at 0).
create or replace function public.tg_event_rsvp_count()
returns trigger
language plpgsql
as $$
begin
  if (tg_op = 'INSERT') then
    update public.events
       set attendee_count = attendee_count + 1
     where id = new.event_id;
    return new;
  elsif (tg_op = 'DELETE') then
    update public.events
       set attendee_count = greatest(0, attendee_count - 1)
     where id = old.event_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_event_rsvp_count_insert on public.event_rsvps;
create trigger trg_event_rsvp_count_insert
  after insert on public.event_rsvps
  for each row execute function public.tg_event_rsvp_count();

drop trigger if exists trg_event_rsvp_count_delete on public.event_rsvps;
create trigger trg_event_rsvp_count_delete
  after delete on public.event_rsvps
  for each row execute function public.tg_event_rsvp_count();

-- =============================================================================
-- 3. Auto-create member row on signup
-- =============================================================================
-- When a new auth.users row is created, automatically insert a corresponding
-- public.members row using the metadata fields populated by the Flutter app
-- (full_name, city, country).
create or replace function public.tg_handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.members (user_id, full_name, profession, city, country, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data ->> 'profession', 'Membre Connecté'),
    coalesce(new.raw_user_meta_data ->> 'city', ''),
    coalesce(new.raw_user_meta_data ->> 'country', ''),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.tg_handle_new_user();

-- =============================================================================
-- 4. View: v_member_profiles
-- =============================================================================
-- Flat join: members + their skills (as a text[] array). The Flutter app
-- uses this single query instead of fetching member + skills separately,
-- avoiding the n+1 problem.
create or replace view public.v_member_profiles
with (security_invoker = true) as
select
  m.id,
  m.user_id,
  m.full_name,
  m.profession,
  m.city,
  m.country,
  m.avatar_url,
  m.initials,
  m.is_verified,
  m.linkedin,
  m.created_at,
  m.updated_at,
  coalesce(
    (
      select array_agg(s.skill order by s.skill)
      from public.member_skills s
      where s.member_id = m.id
    ),
    '{}'::text[]
  ) as skills
from public.members m;

comment on view public.v_member_profiles is
  'Member profiles flattened with their skills. Use this for the directory screen.';

grant select on public.v_member_profiles to anon, authenticated;

-- =============================================================================
-- 5. View: v_event_popularity
-- =============================================================================
-- Events ordered by attendee count (descending) — used for the "trending"
-- section. RLS from the underlying `events` table is inherited.
create or replace view public.v_event_popularity
with (security_invoker = true) as
select
  e.id,
  e.title,
  e.date,
  e.location,
  e.category,
  e.description,
  e.image_url,
  e.attendee_count,
  e.created_at
from public.events e
order by e.attendee_count desc, e.date asc;

comment on view public.v_event_popularity is
  'Events sorted by popularity. Use for the home feed / trending section.';

grant select on public.v_event_popularity to anon, authenticated;

-- =============================================================================
-- 6. View: v_home_feed
-- =============================================================================
-- Posts joined with their author. Saves a round-trip in the Flutter app.
create or replace view public.v_home_feed
with (security_invoker = true) as
select
  p.id,
  p.author_id,
  p.content,
  p.image_url,
  p.likes_count,
  p.comments_count,
  p.time_ago,
  p.created_at,
  m.full_name        as author_name,
  m.city             as author_city,
  m.country          as author_country,
  m.avatar_url       as author_avatar_url,
  m.initials         as author_initials,
  m.is_verified      as author_is_verified
from public.posts p
left join public.members m on m.id = p.author_id
order by p.created_at desc;

comment on view public.v_home_feed is
  'Home feed posts with author info denormalized. Use for the home screen.';

grant select on public.v_home_feed to anon, authenticated;

-- =============================================================================
-- 7. View: v_user_finances
-- =============================================================================
-- Aggregated view: balance + recent transactions + active subscription.
-- Saves the app from 3 round-trips on the finances screen.
create or replace view public.v_user_finances
with (security_invoker = true) as
select
  m.id                                                    as member_id,
  m.user_id                                               as user_id,
  coalesce(sum(t.amount), 0)                              as balance,
  (
    select json_agg(t.* order by t.occurred_at desc)
    from (
      select * from public.transactions
      where user_id = m.id
      order by occurred_at desc
      limit 20
    ) t
  )                                                       as recent_transactions,
  (
    select row_to_json(s.*)
    from public.subscriptions s
    where s.user_id = m.id
  )                                                       as subscription
from public.members m
left join public.transactions t on t.user_id = m.id
group by m.id, m.user_id;

comment on view public.v_user_finances is
  'User finances: balance, recent transactions, active subscription.';

grant select on public.v_user_finances to authenticated;

-- =============================================================================
-- 8. Helper: hex_to_color
-- =============================================================================
-- Converts a #RRGGBB or #AARRGGBB string to a bigint suitable for storage as
-- a numeric color. The Flutter side reverses this in Book.toJson().
create or replace function public.hex_to_color(hex text)
returns bigint
language plpgsql
immutable
as $$
declare
  cleaned text;
begin
  cleaned := lower(regexp_replace(coalesce(hex, ''), '^#', ''));
  if length(cleaned) = 6 then
    cleaned := 'ff' || cleaned;
  end if;
  if length(cleaned) <> 8 then
    return null;
  end if;
  return ('x' || cleaned)::bit(32)::bigint;
exception when others then
  return null;
end;
$$;

-- =============================================================================
-- 9. Realtime: enable for tables that benefit from it
-- =============================================================================
-- Supabase Realtime listens to logical replication. The following tables emit
-- events that the app could subscribe to.
alter publication supabase_realtime add table public.events;
alter publication supabase_realtime add table public.posts;
alter publication supabase_realtime add table public.event_rsvps;
alter publication supabase_realtime add table public.announcements;
alter publication supabase_realtime add table public.community_projects;

-- =============================================================================
-- Done.
-- =============================================================================
-- After running all 4 migrations, the schema is:
--   * 13 tables with proper PKs, FKs, indexes
--   * RLS enabled on all tables with explicit policies
--   * Auto-updated `updated_at` columns
--   * Auto-maintained `events.attendee_count` via RSVP triggers
--   * Auto-created `members` rows on signup (via auth.users trigger)
--   * 4 views that pre-flatten joins for the Flutter app
--   * 1 utility function (hex_to_color)
--   * Realtime enabled on key tables
-- =============================================================================
