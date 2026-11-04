#!/usr/bin/env bats

load helpers

S="$ROOT/skills/groma-methodology/scripts"

setup() {
  P="$BATS_TEST_TMPDIR/p"
  C="$P/openspec/changes"
  mkdir -p "$C/archive"
}

change() { # name [proposal text]
  mkdir -p "$C/$1"
  [ $# -lt 2 ] || printf '%s\n' "$2" > "$C/$1/proposal.md"
}

@test "next id starts at 001" {
  run sh "$S/next-change-id.sh" c --root "$P"
  [ "$output" = "c001" ]
}

@test "next id counts per type" {
  change c001-a; change c003-b; change f001-x
  run sh "$S/next-change-id.sh" c --root "$P"
  [ "$output" = "c004" ]
  run sh "$S/next-change-id.sh" f --root "$P"
  [ "$output" = "f002" ]
  run sh "$S/next-change-id.sh" m --root "$P"
  [ "$output" = "m001" ]
}

@test "next id includes archived changes and strips date prefix" {
  mkdir -p "$C/archive/2026-10-01-f002-null-on-empty"
  run sh "$S/next-change-id.sh" f --root "$P"
  [ "$output" = "f003" ]
}

@test "unknown type is rejected" {
  run sh "$S/next-change-id.sh" x --root "$P"
  [ "$status" -eq 2 ]
  assert_output_contains "unknown change type 'x'"
}

@test "custom type and digits from config" {
  mkdir -p "$P/.groma"
  cat > "$P/.groma/config.yaml" <<'EOF'
conventions:
  changes:
    enabled: true
    digits: 4
    types:
      c: change
      p: performance   # custom
EOF
  change p0001-cache
  run sh "$S/next-change-id.sh" p --root "$P"
  [ "$output" = "p0002" ]
  run sh "$S/next-change-id.sh" f --root "$P"
  [ "$status" -eq 2 ]
}

@test "check passes on conforming names" {
  change m001-mvp; change c001-user-login; change f001-null-on-empty
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "conventions: ok"
}

@test "check reports violation with suggestion" {
  change f002-old; change fix-login
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "VIOLATION	fix-login	suggest f003-login"
}

@test "check suggests change type for add- names" {
  change add-dark-mode
  run sh "$S/check-conventions.sh" --root "$P"
  assert_output_contains "VIOLATION	add-dark-mode	suggest c001-dark-mode"
}

@test "check normalizes uppercase input" {
  change C4-Export
  run sh "$S/check-conventions.sh" --root "$P"
  assert_output_contains "VIOLATION	C4-Export	suggest c001-export"
}

@test "baseline exempts pre-existing changes" {
  change add-dark-mode
  mkdir -p "$P/.groma" && echo "add-dark-mode" > "$P/.groma/conventions-baseline.txt"
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 0 ]
}

@test "check detects duplicate ids across active and archive" {
  change c005-alpha
  mkdir -p "$C/archive/2026-09-01-c005-beta"
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "DUPLICATE	c005	c005-alpha c005-beta"
}

@test "roadmap shows milestone progress and children" {
  change m001-mvp "$(printf '## Why\n\nShip it.\n\n**Goal:** first usable release')"
  change c002-export "$(printf 'Milestone: m001\n\n## Why\nx')"
  change f001-null "$(printf 'Milestone: m001\n')"
  mkdir -p "$C/archive/2026-10-01-c001-login"
  printf 'Milestone: m001\n' > "$C/archive/2026-10-01-c001-login/proposal.md"
  change c003-unrelated "$(printf '## Why\nx')"
  run sh "$S/roadmap.sh" --root "$P" --stdout --today 2026-11-04
  [ "$status" -eq 0 ]
  assert_output_contains "## M001 mvp"
  assert_output_contains "- Goal: first usable release"
  assert_output_contains "- Progress: 1/3 done"
  assert_output_contains '| C001 | `c001-login` | done |'
  assert_output_contains '| F001 | `f001-null` | active |'
  assert_output_contains "## Unassigned active changes"
  assert_output_contains '- `c003-unrelated`'
}

@test "roadmap writes docs/roadmap.md and regenerates its own file" {
  change m001-mvp "$(printf '**Goal:** g')"
  run sh "$S/roadmap.sh" --root "$P" --today 2026-11-04
  [ "$status" -eq 0 ]
  grep -q "generated_by: groma roadmap.sh" "$P/docs/roadmap.md"
  run sh "$S/roadmap.sh" --root "$P" --today 2026-11-05
  grep -q "last_reviewed: 2026-11-05" "$P/docs/roadmap.md"
}

@test "roadmap never overwrites a hand-written roadmap" {
  mkdir -p "$P/docs" && echo "# my roadmap" > "$P/docs/roadmap.md"
  change m001-mvp "$(printf '**Goal:** g')"
  run sh "$S/roadmap.sh" --root "$P"
  [ "$(cat "$P/docs/roadmap.md")" = "# my roadmap" ]
  [ -f "$P/docs/_groma/roadmap.md" ]
}
