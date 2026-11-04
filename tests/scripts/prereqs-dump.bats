#!/usr/bin/env bats

load helpers

PRE="$ROOT/skills/groma/scripts/check-prereqs.sh"
DUMP="$ROOT/skills/groma-survey/scripts/dump-schema.sh"

# Build a PATH with only the given stub tools plus basic utilities.
stub_path() {
  B="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$B"
  for t in sh awk sed cut head tr cat grep date mkdir rm wc; do
    p=$(command -v "$t") && ln -sf "$p" "$B/$t"
  done
  echo "$B"
}

stub() { # name body
  printf '#!/bin/sh\n%s\n' "$2" > "$BATS_TEST_TMPDIR/bin/$1"
  chmod +x "$BATS_TEST_TMPDIR/bin/$1"
}

@test "prereqs: missing node fails, optional tools only reported" {
  P=$(stub_path)
  stub git 'echo "git version 2.45.0"'
  run env PATH="$P" sh "$PRE"
  [ "$status" -eq 1 ]
  assert_output_contains "git	ok	2.45.0"
  assert_output_contains "node	missing"
  assert_output_contains "uv	missing"
}

@test "prereqs: old node is too_old" {
  P=$(stub_path)
  stub git 'echo "git version 2.45.0"'
  stub node 'echo v20.11.0'
  stub npx 'echo 10.2.0'
  run env PATH="$P" sh "$PRE"
  [ "$status" -eq 1 ]
  assert_output_contains "node	too_old	v20.11.0"
}

@test "prereqs: all required present passes" {
  P=$(stub_path)
  stub git 'echo "git version 2.45.0"'
  stub node 'echo v22.4.0'
  stub npx 'echo 10.8.0'
  run env PATH="$P" sh "$PRE"
  [ "$status" -eq 0 ]
  assert_output_contains "node	ok	v22.4.0"
}

@test "dump: postgres via stub never prints the connection string" {
  P=$(stub_path)
  stub pg_dump 'echo "CREATE TABLE public.users (id integer);"'
  cd "$BATS_TEST_TMPDIR"
  run env PATH="$P" DATABASE_URL="postgres://admin:s3cr3t@db.internal:5432/app" sh "$DUMP" postgres
  [ "$status" -eq 0 ]
  assert_output_contains "wrote .groma/schema/schema-postgres.sql (1 tables)"
  assert_output_not_contains "s3cr3t"
  assert_output_not_contains "db.internal"
  ! grep -q "s3cr3t" .groma/schema/schema-postgres.sql
  head -1 .groma/schema/schema-postgres.sql | grep -q "engine=postgres"
}

@test "dump: failing pg_dump hides details" {
  P=$(stub_path)
  stub pg_dump 'echo "connection to db.internal failed for admin:s3cr3t" >&2; exit 1'
  cd "$BATS_TEST_TMPDIR"
  run env PATH="$P" DATABASE_URL="postgres://admin:s3cr3t@db.internal/app" sh "$DUMP" postgres
  [ "$status" -eq 4 ]
  assert_output_not_contains "s3cr3t"
  assert_output_contains "connection details hidden"
}

@test "dump: missing client tool gives install hint" {
  P=$(stub_path)
  cd "$BATS_TEST_TMPDIR"
  run env PATH="$P" sh "$DUMP" mysql app
  [ "$status" -eq 3 ]
  assert_output_contains "'mysqldump' not found"
}

@test "dump: sqlite real schema" {
  command -v sqlite3 >/dev/null || skip "sqlite3 not installed"
  cd "$BATS_TEST_TMPDIR"
  sqlite3 app.db "CREATE TABLE note (id INTEGER PRIMARY KEY, body TEXT); INSERT INTO note VALUES (1, 'secret data');"
  run sh "$DUMP" sqlite app.db --out out
  [ "$status" -eq 0 ]
  grep -q "CREATE TABLE note" out/schema-sqlite.sql
  ! grep -q "secret data" out/schema-sqlite.sql
}

@test "dump: unknown engine shows usage" {
  cd "$BATS_TEST_TMPDIR"
  run sh "$DUMP" oracle
  [ "$status" -eq 2 ]
  assert_output_contains "usage:"
}
