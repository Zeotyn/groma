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

baseline() { # names
  mkdir -p "$P/.groma"
  printf '%s\n' "$@" >> "$P/.groma/conventions-baseline.txt"
}

roadmap() { # text
  mkdir -p "$P/docs"
  printf '%s\n' "$1" > "$P/docs/roadmap.md"
}

# --- next id ------------------------------------------------------------------

@test "next id starts at 1, without padding" {
  run sh "$S/next-change-id.sh" c --root "$P"
  [ "$output" = "c1" ]
}

@test "next id counts per type" {
  change c1-a; change c3-b; change f1-x
  run sh "$S/next-change-id.sh" c --root "$P"
  [ "$output" = "c4" ]
  run sh "$S/next-change-id.sh" f --root "$P"
  [ "$output" = "f2" ]
  run sh "$S/next-change-id.sh" s --root "$P"
  [ "$output" = "s1" ]
}

@test "next id orders numbers, not strings" {
  change c9-a; change c10-b
  run sh "$S/next-change-id.sh" c --root "$P"
  [ "$output" = "c11" ]
}

@test "next id includes archived changes and strips date prefix" {
  mkdir -p "$C/archive/2026-10-01-f2-null-on-empty"
  run sh "$S/next-change-id.sh" f --root "$P"
  [ "$output" = "f3" ]
}

@test "next id counts old padded names in the archive" {
  mkdir -p "$C/archive/2026-11-13-c016-agent-only-init"
  change c009-older
  run sh "$S/next-change-id.sh" c --root "$P"
  [ "$output" = "c17" ]
}

@test "milestone members do not move the numbers of the other types" {
  change m3-fix-rounding; change m3-spike-hooks; change m3-checkout
  run sh "$S/next-change-id.sh" f --root "$P"
  [ "$output" = "f1" ]
  run sh "$S/next-change-id.sh" c --root "$P"
  [ "$output" = "c1" ]
}

@test "next milestone number without a roadmap and without m names is m1" {
  run sh "$S/next-change-id.sh" m --root "$P"
  [ "$output" = "m1" ]
}

@test "next milestone number comes from roadmap headings and m names" {
  roadmap "$(printf '# Roadmap\n\n## M1: First\n\n## M4: Fourth\n\n## Much later\n')"
  change m2-checkout
  run sh "$S/next-change-id.sh" m --root "$P"
  [ "$output" = "m5" ]
  mkdir -p "$C/archive/2026-10-01-m7-spike-hooks"
  run sh "$S/next-change-id.sh" m --root "$P"
  [ "$output" = "m8" ]
}

@test "next milestone number counts old umbrella milestones and old headings" {
  mkdir -p "$C/archive/2026-11-12-m003-v0-3"
  change m004-v0-4
  run sh "$S/next-change-id.sh" m --root "$P"
  [ "$output" = "m5" ]
  roadmap "$(printf '## M006 v0-6\n')"
  run sh "$S/next-change-id.sh" m --root "$P"
  [ "$output" = "m7" ]
}

@test "unknown type is rejected" {
  run sh "$S/next-change-id.sh" x --root "$P"
  [ "$status" -eq 2 ]
  assert_output_contains "unknown change type 'x'"
}

@test "d is unknown: docs belong to the change that causes them" {
  run sh "$S/next-change-id.sh" d --root "$P"
  [ "$status" -eq 2 ]
  assert_output_contains "unknown change type 'd'"
  assert_output_contains "docs belong to the change that causes them"
}

@test "custom type from config, digits ignored" {
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
  [ "$output" = "p2" ]
  run sh "$S/next-change-id.sh" c --root "$P"
  [ "$output" = "c1" ]
  run sh "$S/next-change-id.sh" f --root "$P"
  [ "$status" -eq 2 ]
}

# --- check: names -------------------------------------------------------------

@test "check passes on conforming names" {
  change c4-user-login; change f1-null-on-empty; change s2-graphql; change r10-split-module
  change m3-checkout; change m3-payment; change m3-spike-hooks; change m3-fix-rounding; change m12-refactor-cart
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 0 ]
  [ "$output" = "conventions: ok" ]
}

@test "check reports violation with suggestion" {
  change f2-old; change fix-login
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "VIOLATION	fix-login	suggest f3-login"
  assert_output_contains "conventions: 1 problem(s)"
}

@test "check suggests change type for add- names" {
  change add-dark-mode
  run sh "$S/check-conventions.sh" --root "$P"
  assert_output_contains "VIOLATION	add-dark-mode	suggest c1-dark-mode"
}

@test "check normalizes uppercase input and keeps a free number" {
  change C004-Export
  run sh "$S/check-conventions.sh" --root "$P"
  assert_output_contains "VIOLATION	C004-Export	suggest c4-export"
}

@test "check falls back to the next free number when the wanted one is taken" {
  change c4-other; change c5-more; change C4-Export
  run sh "$S/check-conventions.sh" --root "$P"
  assert_output_contains "VIOLATION	C4-Export	suggest c6-export"
}

@test "padded names are rejected with the unpadded name" {
  change c017-change-naming; change m003-checkout
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "VIOLATION	c017-change-naming	suggest c17-change-naming"
  assert_output_contains "VIOLATION	m003-checkout	suggest m3-checkout"
}

@test "d names are rejected and become a change" {
  change c2-x; change d1-readme
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "VIOLATION	d1-readme	suggest c3-readme"
}

@test "padded and d names in the baseline are accepted" {
  change c016-agent-only-init; change d001-adrs; change m004-v0-4
  mkdir -p "$C/archive/2026-11-12-m003-v0-3"
  baseline c016-agent-only-init d001-adrs m004-v0-4 m003-v0-3
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 0 ]
  [ "$output" = "conventions: ok" ]
}

@test "two violations never get the same suggestion" {
  change fix-login; change fix-logout
  run sh "$S/check-conventions.sh" --root "$P"
  assert_output_contains "suggest f1-login"
  assert_output_contains "suggest f2-logout"
}

@test "baseline exempts pre-existing changes" {
  change add-dark-mode
  baseline add-dark-mode
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 0 ]
}

# --- check: duplicates --------------------------------------------------------

@test "check detects duplicate ids across active and archive" {
  change c5-alpha
  mkdir -p "$C/archive/2026-09-01-c5-beta"
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "DUPLICATE	c5	c5-alpha c5-beta	keep c5-beta, rename c5-alpha to c6-alpha"
}

@test "duplicate active changes: the later created one is renamed" {
  change c5-first; printf 'created: 2026-01-01\n' > "$C/c5-first/.openspec.yaml"
  change c5-second; printf 'created: 2026-02-01\n' > "$C/c5-second/.openspec.yaml"
  run sh "$S/check-conventions.sh" --root "$P"
  assert_output_contains "keep c5-first, rename c5-second to c6-second"
}

@test "an old padded name and a new name with the same number are duplicates" {
  mkdir -p "$C/archive/2026-09-01-c005-code-style"
  baseline c005-code-style
  change c5-export
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "DUPLICATE	c5	c005-code-style c5-export	keep c005-code-style, rename c5-export to c6-export"
}

@test "changes of one milestone share the number without being duplicates" {
  change m3-checkout; change m3-payment; change m3-fix-checkout
  mkdir -p "$C/archive/2026-09-01-m3-cart"
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 0 ]
}

@test "the same full m name active and archived is a duplicate" {
  change m3-checkout
  mkdir -p "$C/archive/2026-09-01-m3-checkout"
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "DUPLICATE	m3-checkout	m3-checkout m3-checkout	keep the archived m3-checkout, give the active change another slug"
}

# --- check: roadmap sections --------------------------------------------------

@test "a milestone section without a marker block is reported with the snippet" {
  roadmap "$(printf '# Roadmap\n\n## M1: MVP\n\n**Goal:** g\n\n<!-- groma:changes m1 -->\n<!-- /groma:changes -->\n\n## M2: Billing\n\n**Goal:** h\n\n## Notes\n\ntext\n')"
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 1 ]
  assert_output_contains 'MARKERS	M2	add the lines "<!-- groma:changes m2 -->" and "<!-- /groma:changes -->" to the section in docs/roadmap.md'
  assert_output_not_contains "MARKERS	M1"
  assert_output_contains "conventions: 1 problem(s)"
}

@test "sections with marker blocks and other headings pass" {
  roadmap "$(printf '## M1: MVP\n<!-- groma:changes m1 -->\n<!-- /groma:changes -->\n## M10: Later\n<!-- groma:changes m10 -->\nx\n<!-- /groma:changes -->\n## Much later\n')"
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 0 ]
}

# --- check: migration suggestions ---------------------------------------------

old_project() {
  change m004-v0-4 "$(printf '## Why\n\nShip it.\n\n**Goal:** v0.4 tagged, all levels green')"
  printf -- '## 1. Child changes\n\n- [x] 1.1 C010 archived\n- [ ] 1.2 C012 archived\n\n## 2. Release gate\n\n- [x] 2.1 Docs reviewed\n- [ ] 2.2 Test levels 1–4 green\n- [ ] 2.3 `v0.4.0` tagged\n' > "$C/m004-v0-4/tasks.md"
  change c012-survey-subagent "$(printf 'Milestone: m004\n\n## Why\nx')"
  change f009-eval-flake "$(printf 'Milestone: m004\n')"
  change s002-hooks "$(printf 'Milestone: m004\n')"
  change r002-split "$(printf 'Milestone: m004\n')"
  change c017-change-naming "$(printf '## Why\nx')"
  change d001-readme
  change c18-new-style
  change add-dark-mode
  mkdir -p "$C/archive/2026-11-12-m003-v0-3" "$C/archive/2026-11-11-c005-code-style"
  printf '**Goal:** v0.3 tagged\n' > "$C/archive/2026-11-12-m003-v0-3/proposal.md"
  printf -- '- [x] 1.1 children\n- [x] 2.1 tagged\n' > "$C/archive/2026-11-12-m003-v0-3/tasks.md"
  printf 'Milestone: m003\n' > "$C/archive/2026-11-11-c005-code-style/proposal.md"
  baseline m004-v0-4 c012-survey-subagent f009-eval-flake s002-hooks r002-split c017-change-naming d001-readme add-dark-mode m003-v0-3 c005-code-style
}

@test "--suggest-migration prints new names for active old names" {
  old_project
  run sh "$S/check-conventions.sh" --root "$P" --suggest-migration
  [ "$status" -eq 0 ]
  assert_output_contains "MIGRATE	c012-survey-subagent	m4-survey-subagent"
  assert_output_contains "MIGRATE	f009-eval-flake	m4-fix-eval-flake"
  assert_output_contains "MIGRATE	s002-hooks	m4-spike-hooks"
  assert_output_contains "MIGRATE	r002-split	m4-refactor-split"
  assert_output_contains "MIGRATE	c017-change-naming	c17-change-naming"
  assert_output_contains "MIGRATE	d001-readme	c19-readme"
  assert_output_contains "MIGRATE	m004-v0-4	roadmap section M4"
  assert_output_not_contains "MIGRATE	c18-new-style"
  assert_output_not_contains "MIGRATE	add-dark-mode"
  assert_output_not_contains "MIGRATE	c005-code-style"
  assert_output_contains "migration: 7 name(s), 2 section(s)"
}

@test "--suggest-migration prints a roadmap section per umbrella milestone" {
  old_project
  run sh "$S/check-conventions.sh" --root "$P" --suggest-migration
  assert_output_contains "SECTION	M4	m004-v0-4
## M4: v0-4

**Goal:** v0.4 tagged, all levels green

**Release gate:**
- [x] Docs reviewed
- [ ] Test levels 1–4 green
- [ ] \`v0.4.0\` tagged

<!-- groma:changes m4 -->
<!-- /groma:changes -->
"
  assert_output_contains "SECTION	M3	m003-v0-3
## M3: v0-3

**Goal:** v0.3 tagged

**Release gate:**

<!-- groma:changes m3 -->
<!-- /groma:changes -->
"
}

@test "--suggest-migration changes no file" {
  old_project
  make_repo "$P"
  commit_at "$P" 2026-11-01 base
  sh "$S/check-conventions.sh" --root "$P" --suggest-migration >/dev/null
  [ -z "$(git -C "$P" status --porcelain)" ]
}

@test "the check is read-only" {
  change fix-login; change c5-a
  mkdir -p "$C/archive/2026-09-01-c5-b"
  roadmap "$(printf '## M2: Billing\n')"
  make_repo "$P"
  commit_at "$P" 2026-11-01 base
  run sh "$S/check-conventions.sh" --root "$P"
  [ "$status" -eq 1 ]
  [ -z "$(git -C "$P" status --porcelain)" ]
}

@test "unknown argument is a usage error" {
  run sh "$S/check-conventions.sh" --rename
  [ "$status" -eq 2 ]
}
