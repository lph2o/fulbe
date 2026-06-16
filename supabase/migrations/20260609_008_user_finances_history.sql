-- =============================================================================
-- Fulɓe Connect — User Finances History View
-- =============================================================================
-- Date    : 2026-06-10
-- Purpose : Aggregate user transactions per month for the last 7 months,
--           replacing the hardcoded chart data in the Flutter app.
-- Order   : Run AFTER 004_functions_triggers.sql (requires v_user_finances)
--
-- The view returns for each member:
--   - member_id / user_id  : FK to members/auth.users
--   - monthly_aggregates    : JSON array of {year, month, amount}
--       ordered chronologically, covering the last 7 months
--       (including the current partial month)
-- =============================================================================

create or replace view public.v_user_finances_history
with (security_invoker = true) as
select
  m.id                                                    as member_id,
  m.user_id                                               as user_id,
  coalesce(
    (
      select json_agg(
        json_build_object(
          'year',   h.year,
          'month',  h.month,
          'amount', h.amount
        )
        order by h.year, h.month
      )
      from (
        select
          extract(year  from t.occurred_at)::int as year,
          extract(month from t.occurred_at)::int as month,
          sum(t.amount)                          as amount
        from public.transactions t
        where t.user_id = m.id
          and t.occurred_at >= date_trunc('month', now()) - interval '6 months'
        group by extract(year from t.occurred_at),
                 extract(month from t.occurred_at)
      ) h
    ),
    '[]'::json
  ) as monthly_aggregates
from public.members m;

comment on view public.v_user_finances_history is
  'User monthly transaction aggregates for the last 7 months. '
  'Use for the finances chart in the Flutter app.';

grant select on public.v_user_finances_history to authenticated;
