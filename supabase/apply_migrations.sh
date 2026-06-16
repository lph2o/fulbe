#!/usr/bin/env bash
# =============================================================================
# Fulɓe Connect — Apply Migrations
# =============================================================================
# Usage:
#   ./supabase/apply_migrations.sh "postgresql://postgres:PASSWORD@db.PROJECT.supabase.co:5432/postgres"
#
# Or set DATABASE_URL in your environment first:
#   export DATABASE_URL="postgresql://postgres:PASSWORD@db.PROJECT.supabase.co:5432/postgres"
#   ./supabase/apply_migrations.sh
# =============================================================================

set -euo pipefail

# Allow DATABASE_URL via env or first arg
DATABASE_URL="${1:-${DATABASE_URL:-}}"

if [ -z "$DATABASE_URL" ]; then
  echo "❌ DATABASE_URL is required."
  echo "   Get it from: Supabase Dashboard → Settings → Database → Connection string (URI mode)"
  echo "   Usage: $0 \"postgresql://postgres:PASSWORD@db.PROJECT.supabase.co:5432/postgres\""
  exit 1
fi

# Check psql
if ! command -v psql >/dev/null 2>&1; then
  echo "❌ psql not found."
  echo "   Install: brew install libpq && echo 'export PATH=\"/opt/homebrew/opt/libpq/bin:\$PATH\"' >> ~/.zshrc"
  echo "   Or use the Supabase Dashboard SQL editor (see supabase/README.md)."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIG_DIR="${SCRIPT_DIR}/migrations"

if [ ! -d "$MIG_DIR" ]; then
  echo "❌ Migrations directory not found: $MIG_DIR"
  exit 1
fi

# Apply in alphabetical order (timestamp prefix ensures this)
MIGRATIONS=(
  "20260609_001_init_schema.sql"
  "20260609_002_rls_policies.sql"
  "20260609_003_seed_dev_data.sql"
  "20260609_004_functions_triggers.sql"
)

echo "🚀 Applying $(echo "${#MIGRATIONS[@]}") migrations to Supabase..."
echo

for mig in "${MIGRATIONS[@]}"; do
  path="$MIG_DIR/$mig"
  if [ ! -f "$path" ]; then
    echo "❌ Missing: $path"
    exit 1
  fi
  echo "▶ $mig"
  psql "$DATABASE_URL" \
    --set ON_ERROR_STOP=on \
    --single-transaction \
    --quiet \
    -f "$path"
  echo "  ✓ done"
  echo
done

echo "✅ All migrations applied successfully!"
echo
echo "Quick verification queries:"
echo "  psql \"\$DATABASE_URL\" -c \"select count(*) from public.events;\"     # expect 5"
echo "  psql \"\$DATABASE_URL\" -c \"select count(*) from public.members;\"    # expect 8"
echo "  psql \"\$DATABASE_URL\" -c \"select tablename, rowsecurity from pg_tables where schemaname='public';\""
