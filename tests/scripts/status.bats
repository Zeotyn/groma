#!/usr/bin/env bats

load helpers

ST="$ROOT/skills/groma-methodology/scripts/status.sh"

setup() {
  P="$BATS_TEST_TMPDIR/p"
  make_repo "$P"
  C="$P/openspec/changes"
  mkdir -p "$C/archive" "$P/src" "$P/tests"
  echo x > "$P/src/a.js"
}

tasks() { # change done open
  mkdir -p "$C/$1"
  : > "$C/$1/tasks.md"
  i=0; while [ "$i" -lt "$2" ]; do echo "- [x] 1.$i done" >> "$C/$1/tasks.md"; i=$((i + 1)); done
  i=0; while [ "$i" -lt "$3" ]; do echo "- [ ] 2.$i open" >> "$C/$1/tasks.md"; i=$((i + 1)); done
}

@test "all tasks done: verify, then archive" {
  tasks c001-groma-suite 3 0
  echo t > "$P/tests/a.test.js"
  commit_at "$P" 2026-11-01 work
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$status" -eq 0 ]
  assert_output_contains "c001-groma-suite  3/3 tasks → verify, then archive"
}

@test "no commit for longer than stale_change_days: continue or close" {
  tasks c004-export 1 2
  echo t > "$P/tests/a.test.js"
  commit_at "$P" 2026-10-01 old
  run sh "$ST" --root "$P" --today 2026-11-04
  assert_output_contains "c004-export  1/3 tasks → no commit for 34 days, continue or close"
}

@test "tasks ticked after the last test change: add or run tests" {
  echo t > "$P/tests/a.test.js"
  commit_at "$P" 2026-11-01 tests
  tasks f002-null 2 1
  commit_at "$P" 2026-11-03 ticked
  run sh "$ST" --root "$P" --today 2026-11-04
  assert_output_contains "f002-null  2/3 tasks → tasks ticked since the last test change, add or run tests"
}

@test "uncommitted ticks also count as untested" {
  echo t > "$P/tests/a.test.js"
  tasks f002-null 0 2
  commit_at "$P" 2026-11-01 all
  sed -i.bak 's/- \[ \] 2.0/- [x] 2.0/' "$C/f002-null/tasks.md" && rm "$C/f002-null/tasks.md.bak"
  run sh "$ST" --root "$P" --today 2026-11-04
  assert_output_contains "f002-null  1/2 tasks → tasks ticked since the last test change"
}

@test "only one reminder per change, archive wins" {
  tasks c001-a 2 0
  commit_at "$P" 2026-09-01 old
  run sh "$ST" --root "$P" --today 2026-11-04
  assert_output_contains "c001-a  2/2 tasks → verify, then archive"
  assert_output_not_contains "no commit for"
}

@test "nothing open prints one line" {
  echo t > "$P/tests/a.test.js"
  tasks c002-b 0 3
  commit_at "$P" 2026-11-03 fresh
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "groma status: nothing open" ]
}

@test "archived changes are ignored" {
  mkdir -p "$C/archive/2026-10-01-c001-old"
  printf -- '- [x] 1 done\n' > "$C/archive/2026-10-01-c001-old/tasks.md"
  commit_at "$P" 2026-11-03 x
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "groma status: nothing open" ]
}

@test "reminders can be disabled in the config" {
  tasks c001-a 2 0
  tasks c004-b 1 1
  commit_at "$P" 2026-09-01 old
  mkdir -p "$P/.groma"
  printf 'reminders:\n  archive_when_done: false\n  stale_change_days: 0\n  untested_tasks: false\n' > "$P/.groma/config.yaml"
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "groma status: nothing open" ]
}

@test "is read-only" {
  tasks c001-a 2 0
  commit_at "$P" 2026-11-01 x
  sh "$ST" --root "$P" --today 2026-11-04 >/dev/null
  [ -z "$(git -C "$P" status --porcelain)" ]
}

@test "OpenSpec spec files do not count as test changes" {
  tasks c003-x 1 1
  commit_at "$P" 2026-11-01 ticked
  mkdir -p "$P/openspec/specs/cap" && echo "# spec" > "$P/openspec/specs/cap/spec.md"
  commit_at "$P" 2026-11-02 specs
  run sh "$ST" --root "$P" --today 2026-11-04
  assert_output_contains "c003-x  1/2 tasks → tasks ticked since the last test change"
}

@test "milestone and docs changes get no test reminder" {
  tasks m001-mvp 1 2
  tasks d001-adrs 1 1
  commit_at "$P" 2026-11-03 x
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "groma status: nothing open" ]
}
