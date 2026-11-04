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
  printf 'reminders:\n  archive_when_done: false\n  stale_change_days: 0\n  untested_tasks: false\n  uncommitted: false\n' > "$P/.groma/config.yaml"
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
  tasks c009-child 0 1
  printf 'Milestone: m001\n' > "$C/c009-child/proposal.md"
  commit_at "$P" 2026-11-03 x
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "groma status: nothing open" ]
}

# --- living docs (C004) -------------------------------------------------------------

docs_setup() { # doc with sources [src/], change c007-cache proposed later, then code changed
  mkdir -p "$P/docs"
  printf -- '---\nsources: [src/]\n---\n# Architecture\n' > "$P/docs/architecture.md"
  echo t > "$P/tests/a.test.js"
  commit_at "$P" 2026-10-01 base
  tasks c007-cache 2 0
  echo "## Why" > "$C/c007-cache/proposal.md"
  commit_at "$P" 2026-11-01 propose
  echo y > "$P/src/a.js"
  commit_at "$P" 2026-11-02 code
}

@test "done but docs impact open: docs reminder wins over archive" {
  docs_setup
  run sh "$ST" --root "$P" --today 2026-11-04
  assert_output_contains "c007-cache  2/2 tasks → update docs/architecture.md or add a Docs: task line"
  assert_output_not_contains "verify, then archive"
}

@test "docs.gate off: no docs reminder" {
  docs_setup
  mkdir -p "$P/.groma"
  printf 'docs:\n  gate: off\n' > "$P/.groma/config.yaml"
  run sh "$ST" --root "$P" --today 2026-11-04
  assert_output_contains "c007-cache  2/2 tasks → verify, then archive"
}

@test "proposed ADR whose origin change is archived: accept or reject" {
  mkdir -p "$C/archive/2026-10-20-c007-cache" "$C/c008-next" "$P/docs/adr"
  printf -- '- [x] 1 done\n' > "$C/archive/2026-10-20-c007-cache/tasks.md"
  printf -- '---\nstatus: proposed\norigin: c007-cache#D2\n---\n# Use Redis\n' > "$P/docs/adr/0011-use-redis.md"
  printf -- '---\nstatus: accepted\norigin: c007-cache#D1\n---\n# Cache reads\n' > "$P/docs/adr/0010-cache-reads.md"
  printf -- '---\nstatus: proposed\norigin: c008-next#D1\n---\n# Next\n' > "$P/docs/adr/0012-next.md"
  echo t > "$P/tests/a.test.js"
  commit_at "$P" 2026-11-03 x
  run sh "$ST" --root "$P" --today 2026-11-04
  assert_output_contains "ADR 0011 still proposed (c007-cache archived) → accept or reject"
  assert_output_not_contains "ADR 0010"
  assert_output_not_contains "ADR 0012"
}

@test "done, docs clean, decision without ADR: ADR reminder" {
  docs_setup
  echo "Updated." >> "$P/docs/architecture.md"
  printf '### D1: Use Redis\nAlternatives: a map.\n' > "$C/c007-cache/design.md"
  commit_at "$P" 2026-11-03 design
  run sh "$ST" --root "$P" --today 2026-11-04
  assert_output_contains "c007-cache  2/2 tasks → write a proposed ADR for c007-cache#D1"
}

@test "quoted values and trailing spaces in config and ADRs" {
  docs_setup
  mkdir -p "$P/.groma" "$P/docs/adr" "$C/archive/2026-10-01-c006-old"
  printf 'docs:  \n  gate: "off"\n' > "$P/.groma/config.yaml"
  run sh "$ST" --root "$P" --today 2026-11-04
  assert_output_contains "c007-cache  2/2 tasks → verify, then archive"
  printf 'docs:\n  gate: review\n' > "$P/.groma/config.yaml"
  printf -- '- [x] 1\n' > "$C/archive/2026-10-01-c006-old/tasks.md"
  printf -- '---\nstatus: "proposed"\norigin: "c006-old#D1"\n---\n' > "$P/docs/adr/0003-x.md"
  run sh "$ST" --root "$P" --today 2026-11-04
  assert_output_contains "ADR 0003 still proposed (c006-old archived)"
}

# --- milestone gates and repository state (F002) ------------------------------------

milestone() { # change done open: open tasks are the gate tasks
  tasks "$1" "$2" 0
  i=0; while [ "$i" -lt "$3" ]; do echo "- [ ] 2.$((i + 1)) Test levels 1–4 green" >> "$C/$1/tasks.md"; i=$((i + 1)); done
}

@test "milestone without active children: gate reminder with the first open task" {
  milestone m002-v0-2 3 4
  echo t > "$P/tests/a.test.js"
  commit_at "$P" 2026-11-03 x
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "m002-v0-2  3/7 tasks → gate: 2.1 Test levels 1–4 green" ]
}

@test "gate text loses backticks and is cut to 60 characters" {
  tasks m002-v0-2 1 0
  echo '- [ ] 2.1 Run `scripts/test.sh` and then a very long explanation that goes on and on' >> "$C/m002-v0-2/tasks.md"
  commit_at "$P" 2026-11-03 x
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "m002-v0-2  1/2 tasks → gate: 2.1 Run scripts/test.sh and then a very long explanation tha" ]
}

@test "gate text is cut by characters, not bytes" {
  tasks m002-v0-2 1 0
  a=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa   # 54 characters
  echo "- [ ] 2.1 ${a}–ü and more" >> "$C/m002-v0-2/tasks.md"
  commit_at "$P" 2026-11-03 x
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "m002-v0-2  1/2 tasks → gate: 2.1 ${a}–ü" ]
}

@test "milestone references are found in a project path with spaces" {
  P="$BATS_TEST_TMPDIR/my project"
  make_repo "$P"
  C="$P/openspec/changes"
  milestone m003-v0-3 1 2
  tasks c005-code-style 0 2
  printf 'Milestone: m003\n' > "$C/c005-code-style/proposal.md"
  milestone m004-v0-4 1 1
  commit_at "$P" 2026-11-03 x
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "m004-v0-4  1/2 tasks → gate: 2.1 Test levels 1–4 green" ]
}

@test "milestone with an active child: no gate reminder" {
  milestone m003-v0-3 1 2
  tasks c005-code-style 0 2
  printf 'Milestone: m003\n\n## Why\n' > "$C/c005-code-style/proposal.md"
  echo t > "$P/tests/a.test.js"
  commit_at "$P" 2026-11-03 x
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "groma status: nothing open" ]
}

@test "gate replaces the stale reminder" {
  milestone m002-v0-2 3 4
  commit_at "$P" 2026-09-01 old
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "m002-v0-2  3/7 tasks → gate: 2.1 Test levels 1–4 green" ]
}

@test "uncommitted files are counted" {
  commit_at "$P" 2026-11-03 x
  echo y > "$P/src/a.js"; echo n > "$P/src/b.js"; echo n > "$P/src/c.js"; echo n > "$P/tests/d.test.js"
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "working tree: 4 files uncommitted → commit or stash" ]
}

upstream() { # bare remote with main pushed and tracked
  git init -q --bare "$BATS_TEST_TMPDIR/r.git"
  git -C "$P" remote add origin "$BATS_TEST_TMPDIR/r.git"
  git -C "$P" push -q -u origin main 2>/dev/null
}

@test "local commits on main that its upstream lacks are counted" {
  commit_at "$P" 2026-11-01 base
  upstream
  echo 1 > "$P/src/a.js"; commit_at "$P" 2026-11-02 one
  echo 2 > "$P/src/a.js"; commit_at "$P" 2026-11-03 two
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "main: 2 commits not pushed → git push" ]
}

@test "unpushed counts main, not the current branch" {
  commit_at "$P" 2026-11-01 base
  upstream
  echo 1 > "$P/src/a.js"; commit_at "$P" 2026-11-02 one
  git -C "$P" checkout -q -b c009-work
  echo 2 > "$P/src/a.js"; commit_at "$P" 2026-11-03 two
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "main: 1 commits not pushed → git push" ]
}

@test "main branch comes from origin/HEAD" {
  git -C "$P" checkout -q -b trunk
  commit_at "$P" 2026-11-01 base
  git init -q --bare "$BATS_TEST_TMPDIR/r.git"
  git -C "$P" remote add origin "$BATS_TEST_TMPDIR/r.git"
  git -C "$P" push -q -u origin trunk 2>/dev/null
  git -C "$P" remote set-head origin trunk
  echo 1 > "$P/src/a.js"; commit_at "$P" 2026-11-02 one
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "trunk: 1 commits not pushed → git push" ]
}

@test "without origin/HEAD and main, master is the main branch" {
  git -C "$P" checkout -q -b master
  commit_at "$P" 2026-11-01 base
  git -C "$P" branch -q -D main 2>/dev/null || true
  git init -q --bare "$BATS_TEST_TMPDIR/r.git"
  git -C "$P" remote add origin "$BATS_TEST_TMPDIR/r.git"
  git -C "$P" push -q -u origin master 2>/dev/null
  echo 1 > "$P/src/a.js"; commit_at "$P" 2026-11-02 one
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "master: 1 commits not pushed → git push" ]
}

@test "no upstream: no unpushed line" {
  commit_at "$P" 2026-11-01 base
  echo 1 > "$P/src/a.js"; commit_at "$P" 2026-11-02 one
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "groma status: nothing open" ]
}

@test "repository reminders can be disabled" {
  mkdir -p "$P/.groma"
  printf 'reminders:\n  uncommitted: false\n  unpushed: false\n' > "$P/.groma/config.yaml"
  commit_at "$P" 2026-11-01 base
  upstream
  echo 1 > "$P/src/a.js"; commit_at "$P" 2026-11-02 one
  echo 2 > "$P/src/a.js"
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "groma status: nothing open" ]
}

@test "repository lines come after change lines, without the nothing-open line" {
  tasks c001-a 2 0
  echo t > "$P/tests/a.test.js"
  commit_at "$P" 2026-11-01 x
  echo y > "$P/src/a.js"
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "c001-a  2/2 tasks → verify, then archive
working tree: 1 files uncommitted → commit or stash" ]
}

@test "outside git: no repository lines" {
  rm -rf "$P/.git"
  run sh "$ST" --root "$P" --today 2026-11-04
  [ "$output" = "groma status: nothing open" ]
}
