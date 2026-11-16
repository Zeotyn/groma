#!/usr/bin/env bats

load helpers

S="$ROOT/skills/groma-methodology/scripts"

setup() {
  P="$BATS_TEST_TMPDIR/p"
  C="$P/openspec/changes"
  mkdir -p "$C/archive" "$P/docs"
}

change() { # name done open [proposal text]
  mkdir -p "$C/$1"
  : > "$C/$1/tasks.md"
  i=0; while [ "$i" -lt "$2" ]; do echo "- [x] 1.$i done" >> "$C/$1/tasks.md"; i=$((i + 1)); done
  i=0; while [ "$i" -lt "$3" ]; do echo "- [ ] 2.$i open" >> "$C/$1/tasks.md"; i=$((i + 1)); done
  [ $# -lt 4 ] || printf '%s\n' "$4" > "$C/$1/proposal.md"
}

write_roadmap() {
  cat > "$P/docs/roadmap.md" <<'EOF'
---
title: Roadmap
owner: me
---

# Roadmap

Hand-written intro with  two spaces, kept as written.

## M1: MVP

**Goal:** first usable release

**Release gate:**
- [x] Tests green
- [ ] v1.0 tagged

<!-- groma:changes m1 -->
old text that the script replaces
<!-- /groma:changes -->

Notes below the block stay.

## M2: Billing

**Goal:** invoices

<!-- groma:changes m2 -->
<!-- /groma:changes -->

## M3: No markers

**Goal:** later
EOF
}

@test "fills each marker block with the changes of its milestone" {
  write_roadmap
  change m1-checkout 2 3
  change m1-fix-rounding 1 0
  mkdir -p "$C/archive"; change archive/2026-10-01-m1-login 4 0
  change m2-spike-invoices 0 2
  change m10-other 0 1
  change c7-unrelated 0 1
  run sh "$S/roadmap.sh" --root "$P"
  [ "$status" -eq 0 ]
  [ "$output" = "summary	blocks=2	changed=1" ]
  run cat "$P/docs/roadmap.md"
  assert_output_contains '<!-- groma:changes m1 -->
| Change | State | Tasks |
|---|---|---|
| `m1-checkout` | active | 2/5 |
| `m1-fix-rounding` | active | 1/1 |
| `m1-login` | archived | - |
<!-- /groma:changes -->'
  assert_output_contains '<!-- groma:changes m2 -->
| Change | State | Tasks |
|---|---|---|
| `m2-spike-invoices` | active | 0/2 |
<!-- /groma:changes -->'
  assert_output_not_contains "old text that the script replaces"
  assert_output_not_contains "m10-other"
  assert_output_not_contains "c7-unrelated"
}

@test "text outside the marker blocks stays byte-identical" {
  write_roadmap
  cp "$P/docs/roadmap.md" "$BATS_TEST_TMPDIR/before.md"
  change m1-checkout 2 3
  change m2-invoices 0 2
  sh "$S/roadmap.sh" --root "$P"
  strip() { awk '/<!-- groma:changes m[0-9]+ -->/ { print; skip = 1; next } /<!-- \/groma:changes -->/ { skip = 0 } !skip' "$1"; }
  strip "$BATS_TEST_TMPDIR/before.md" > "$BATS_TEST_TMPDIR/a"
  strip "$P/docs/roadmap.md" > "$BATS_TEST_TMPDIR/b"
  cmp "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR/b"
}

@test "a milestone without changes gets a placeholder line" {
  write_roadmap
  run sh "$S/roadmap.sh" --root "$P" --stdout
  assert_output_contains '<!-- groma:changes m2 -->
No changes yet.
<!-- /groma:changes -->'
}

@test "a section without markers stays untouched and gets none" {
  write_roadmap
  change m3-later 0 1
  sh "$S/roadmap.sh" --root "$P"
  [ "$(grep -c 'groma:changes m' "$P/docs/roadmap.md")" -eq 2 ]
  ! grep -q 'm3-later' "$P/docs/roadmap.md"
  [ "$(tail -n 1 "$P/docs/roadmap.md")" = "**Goal:** later" ]
}

@test "a second run changes nothing" {
  write_roadmap
  change m1-checkout 2 3
  sh "$S/roadmap.sh" --root "$P"
  cp "$P/docs/roadmap.md" "$BATS_TEST_TMPDIR/first.md"
  run sh "$S/roadmap.sh" --root "$P"
  [ "$output" = "summary	blocks=2	changed=0" ]
  cmp "$BATS_TEST_TMPDIR/first.md" "$P/docs/roadmap.md"
}

@test "--stdout prints the result and writes nothing" {
  write_roadmap
  cp "$P/docs/roadmap.md" "$BATS_TEST_TMPDIR/before.md"
  change m1-checkout 2 3
  run sh "$S/roadmap.sh" --root "$P" --stdout
  [ "$status" -eq 0 ]
  assert_output_contains '| `m1-checkout` | active | 2/5 |'
  cmp "$BATS_TEST_TMPDIR/before.md" "$P/docs/roadmap.md"
  [ "$(ls "$P/docs")" = "roadmap.md" ]
}

@test "baseline changes join their milestone through the Milestone: line" {
  write_roadmap
  change c002-export 1 1 "$(printf 'Milestone: m001\n\n## Why\nx')"
  change archive/2026-10-01-f001-null 2 0 "Milestone: m001"
  change c003-not-in-baseline 0 1 "Milestone: m001"
  change m001-mvp 1 1 "**Goal:** g"
  mkdir -p "$P/.groma"
  printf 'c002-export\nf001-null\nm001-mvp\n' > "$P/.groma/conventions-baseline.txt"
  run sh "$S/roadmap.sh" --root "$P" --stdout
  assert_output_contains '<!-- groma:changes m1 -->
| Change | State | Tasks |
|---|---|---|
| `c002-export` | active | 1/2 |
| `f001-null` | archived | - |
<!-- /groma:changes -->'
  assert_output_not_contains "c003-not-in-baseline"
  assert_output_not_contains '`m001-mvp`'
}

@test "marker numbers are compared as numbers, a change without tasks shows a dash" {
  printf '## M3: X\n<!-- groma:changes M03 -->\n<!-- /groma:changes -->\n' > "$P/docs/roadmap.md"
  mkdir -p "$C/m3-checkout"
  run sh "$S/roadmap.sh" --root "$P" --stdout
  assert_output_contains '| `m3-checkout` | active | - |'
}

@test "a CRLF roadmap is filled and stays CRLF" {
  printf '# Roadmap\r\n\r\n## M1: MVP\r\n\r\n**Goal:** g\r\n\r\n<!-- groma:changes m1 -->\r\nold\r\n<!-- /groma:changes -->\r\n\r\nEnd.\r\n' > "$P/docs/roadmap.md"
  change m1-checkout 2 3
  run sh "$S/roadmap.sh" --root "$P"
  [ "$output" = "summary	blocks=1	changed=1" ]
  grep -q "$(printf '^| `m1-checkout` | active | 2/5 |\r$')" "$P/docs/roadmap.md"
  ! grep -q '^old' "$P/docs/roadmap.md"
  # every line still ends in CR LF
  [ "$(grep -c "$(printf '\r$')" "$P/docs/roadmap.md")" -eq "$(wc -l < "$P/docs/roadmap.md" | tr -d ' ')" ]
  run sh "$S/roadmap.sh" --root "$P"
  [ "$output" = "summary	blocks=1	changed=0" ]
}

@test "a file without a final newline gets none" {
  printf '## M1: MVP\n<!-- groma:changes m1 -->\n<!-- /groma:changes -->\nlast line' > "$P/docs/roadmap.md"
  change m1-checkout 2 3
  run sh "$S/roadmap.sh" --root "$P"
  [ "$output" = "summary	blocks=1	changed=1" ]
  [ "$(tail -c 9 "$P/docs/roadmap.md")" = "last line" ]
  [ "$(tail -c 1 "$P/docs/roadmap.md" | wc -l | tr -d ' ')" -eq 0 ]
  grep -q 'm1-checkout' "$P/docs/roadmap.md"
  # an unchanged block leaves the file as it is, byte for byte
  cp "$P/docs/roadmap.md" "$BATS_TEST_TMPDIR/first.md"
  run sh "$S/roadmap.sh" --root "$P"
  [ "$output" = "summary	blocks=1	changed=0" ]
  cmp "$BATS_TEST_TMPDIR/first.md" "$P/docs/roadmap.md"
  run sh "$S/roadmap.sh" --root "$P" --stdout
  [ "$(printf '%s' "$output" | tail -n 1)" = "last line" ]
}

@test "no roadmap: nothing is created" {
  rmdir "$P/docs"
  change m1-checkout 0 1
  run sh "$S/roadmap.sh" --root "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "summary	blocks=0	changed=0"
  [ ! -e "$P/docs" ]
}

@test "a roadmap without marker blocks stays as it is, also one of the old generator" {
  printf -- '---\ngenerated_by: groma roadmap.sh\n---\n\n# Roadmap\n\n## M001 mvp\n' > "$P/docs/roadmap.md"
  cp "$P/docs/roadmap.md" "$BATS_TEST_TMPDIR/before.md"
  change m001-mvp 0 1
  run sh "$S/roadmap.sh" --root "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "check-conventions.sh --suggest-migration"
  assert_output_contains "summary	blocks=0	changed=0"
  cmp "$BATS_TEST_TMPDIR/before.md" "$P/docs/roadmap.md"
  [ ! -e "$P/docs/_groma" ]
}

@test "an unclosed marker block writes nothing and fails" {
  printf '## M1: X\n<!-- groma:changes m1 -->\ntext\n' > "$P/docs/roadmap.md"
  cp "$P/docs/roadmap.md" "$BATS_TEST_TMPDIR/before.md"
  run sh "$S/roadmap.sh" --root "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "no closing line"
  cmp "$BATS_TEST_TMPDIR/before.md" "$P/docs/roadmap.md"
  [ "$(ls "$P/docs")" = "roadmap.md" ]
}

@test "unknown argument is a usage error" {
  run sh "$S/roadmap.sh" --frobnicate
  [ "$status" -eq 2 ]
}
