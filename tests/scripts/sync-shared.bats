#!/usr/bin/env bats

load helpers

setup() {
  R="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$R/scripts" "$R/skills/groma-a/references" "$R/skills/groma-b"
  cp "$ROOT/scripts/sync-shared.sh" "$R/scripts/"
  printf 'table v1\n' > "$R/skills/groma-a/references/t.md"
  printf '# comment\n\nskills/groma-a/references/t.md -> skills/groma-b/references/t.md\n' > "$R/scripts/shared-files.txt"
}

@test "the repository's vendored copies match their sources" {
  run sh "$ROOT/scripts/sync-shared.sh" --check
  [ "$status" -eq 0 ]
  assert_output_contains "summary	differs=0"
}

@test "copies a missing consumer, creating its folder" {
  run sh "$R/scripts/sync-shared.sh"
  [ "$status" -eq 0 ]
  assert_output_contains "copied	skills/groma-b/references/t.md"
  assert_output_contains "summary	copied=1"
  cmp "$R/skills/groma-a/references/t.md" "$R/skills/groma-b/references/t.md"
}

@test "identical copies are left alone" {
  sh "$R/scripts/sync-shared.sh" >/dev/null
  run sh "$R/scripts/sync-shared.sh"
  assert_output_contains "summary	copied=0"
}

@test "--check reports a drifted copy and changes nothing" {
  sh "$R/scripts/sync-shared.sh" >/dev/null
  printf 'edited\n' > "$R/skills/groma-b/references/t.md"
  run sh "$R/scripts/sync-shared.sh" --check
  [ "$status" -eq 1 ]
  assert_output_contains "differs	skills/groma-b/references/t.md	skills/groma-a/references/t.md"
  [ "$(cat "$R/skills/groma-b/references/t.md")" = edited ]
}

@test "missing source and malformed line fail" {
  printf 'skills/groma-a/nope.md -> skills/groma-b/nope.md\n' > "$R/scripts/shared-files.txt"
  run sh "$R/scripts/sync-shared.sh"
  [ "$status" -eq 1 ]
  assert_output_contains "source missing: skills/groma-a/nope.md"
  printf 'just-one-path\n' > "$R/scripts/shared-files.txt"
  run sh "$R/scripts/sync-shared.sh"
  [ "$status" -eq 1 ]
  assert_output_contains "expected '<source> -> <consumer>'"
}

@test "usage error exits 2" {
  run sh "$R/scripts/sync-shared.sh" --nope
  [ "$status" -eq 2 ]
}
