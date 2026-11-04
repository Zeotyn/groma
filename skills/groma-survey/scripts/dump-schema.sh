#!/bin/sh
# Write a schema-only dump that groma can read. Run this YOURSELF; the agent
# never connects to databases and never sees your credentials.
#
# Usage:
#   dump-schema.sh postgres            uses DATABASE_URL or the standard PG* env vars
#   dump-schema.sh mysql <database>    uses ~/.my.cnf or MYSQL_* env vars
#   dump-schema.sh sqlite <file.db>
#   options: --out <dir>   (default: .groma/schema)
#
# Output: <out>/schema-<engine>.sql with a header line containing engine and date.
# The script never prints connection strings, hosts or passwords.
set -eu

OUT=.groma/schema
ENGINE=""
ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT=$2; shift 2 ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) if [ -z "$ENGINE" ]; then ENGINE=$1; else ARG=$1; fi; shift ;;
  esac
done

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "error: '$1' not found. Install the $2 client tools first." >&2; exit 3; }
}

mkdir -p "$OUT"
FILE="$OUT/schema-$ENGINE.sql"
TMP="$FILE.tmp.$$"
trap 'rm -f "$TMP"' EXIT
STAMP=$(date -u +%Y-%m-%d)

case "$ENGINE" in
  postgres)
    need pg_dump PostgreSQL
    if [ -n "${DATABASE_URL:-}" ]; then
      pg_dump --schema-only --no-owner --no-privileges "$DATABASE_URL" > "$TMP" 2>/dev/null \
        || { echo "error: pg_dump failed (connection details hidden). Check DATABASE_URL." >&2; exit 4; }
    else
      pg_dump --schema-only --no-owner --no-privileges > "$TMP" 2>/dev/null \
        || { echo "error: pg_dump failed (connection details hidden). Check PGHOST/PGUSER/PGDATABASE." >&2; exit 4; }
    fi
    ;;
  mysql)
    need mysqldump MySQL
    [ -n "$ARG" ] || { echo "usage: $0 mysql <database>" >&2; exit 2; }
    mysqldump --no-data --skip-comments --skip-add-drop-table "$ARG" > "$TMP" 2>/dev/null \
      || { echo "error: mysqldump failed (connection details hidden)." >&2; exit 4; }
    ;;
  sqlite)
    need sqlite3 SQLite
    [ -n "$ARG" ] && [ -f "$ARG" ] || { echo "usage: $0 sqlite <file.db>" >&2; exit 2; }
    sqlite3 "$ARG" .schema > "$TMP" 2>/dev/null || { echo "error: sqlite3 failed." >&2; exit 4; }
    ;;
  *)
    echo "usage: $0 postgres | mysql <database> | sqlite <file.db> [--out <dir>]" >&2
    exit 2
    ;;
esac

{ echo "-- groma schema dump: engine=$ENGINE date=$STAMP (schema only, no data)"; cat "$TMP"; } > "$FILE"
echo "wrote $FILE ($(grep -ci 'create table' "$FILE" || true) tables)"
