#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load helpers

NX="$ROOT/skills/groma-methodology/scripts/next.sh"
STOP="$ROOT/skills/groma-methodology/scripts/next-stop.sh"

setup() {
  # a throwaway home: an unset next.hook follows the flag file $HOME/.claude/.groma-next-always
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  P="$BATS_TEST_TMPDIR/p"
  make_repo "$P"
  C="$P/openspec/changes"
  mkdir -p "$C/archive" "$P/src" "$P/tests"
  echo x > "$P/src/a.js"
  echo t > "$P/tests/a.test.js"
}

tasks() { # change done open
  mkdir -p "$C/$1"
  : > "$C/$1/tasks.md"
  i=0; while [ "$i" -lt "$2" ]; do echo "- [x] 1.$i done" >> "$C/$1/tasks.md"; i=$((i + 1)); done
  i=0; while [ "$i" -lt "$3" ]; do echo "- [ ] 2.$i open" >> "$C/$1/tasks.md"; i=$((i + 1)); done
}

groma_dir() { # .groma/ with an optional config body
  mkdir -p "$P/.groma"
  [ $# -eq 0 ] || printf '%b' "$1" > "$P/.groma/config.yaml"
}

upstream() { # bare remote with main pushed and tracked
  git init -q --bare "$BATS_TEST_TMPDIR/r.git"
  git -C "$P" remote add origin "$BATS_TEST_TMPDIR/r.git"
  git -C "$P" push -q -u origin main 2>/dev/null
}

unpushed() { # n commits on main after the upstream
  i=0; while [ "$i" -lt "$1" ]; do echo "$i" > "$P/src/a.js"; commit_at "$P" 2026-11-02 "c$i"; i=$((i + 1)); done
}

proposed_adr() { # number origin: proposed ADR whose origin change is archived
  mkdir -p "$C/archive/2026-10-20-$2" "$P/docs/adr"
  printf -- '- [x] 1 done\n' > "$C/archive/2026-10-20-$2/tasks.md"
  printf -- '---\nstatus: proposed\norigin: %s#D2\n---\n# Decision\n' "$2" > "$P/docs/adr/$1-decision.md"
}

docs_open() { # c007-cache: all tasks done, docs/architecture.md behind its sources
  mkdir -p "$P/docs"
  printf -- '---\nsources: [src/]\n---\n# Architecture\n' > "$P/docs/architecture.md"
  commit_at "$P" 2026-10-01 base
  tasks c007-cache 2 0
  echo "## Why" > "$C/c007-cache/proposal.md"
  commit_at "$P" 2026-11-01 propose
  echo y > "$P/src/a.js"
  commit_at "$P" 2026-11-02 code
}

conflict() { # leaves branch "topic" and main with conflicting commits, HEAD on main
  commit_at "$P" 2026-11-01 base
  git -C "$P" checkout -q -b topic
  echo topic > "$P/src/a.js"; commit_at "$P" 2026-11-02 topic
  git -C "$P" checkout -q main
  echo main > "$P/src/a.js"; commit_at "$P" 2026-11-03 main
}

json_field() { # field: reads $output as JSON
  printf '%s' "$output" | node -e 'let s = ""; process.stdin.on("data", d => s += d).on("end", () => {
    const o = JSON.parse(s); process.stdout.write(String(o[process.argv[1]])); })' "$1"
}

# --- the ladder, rung by rung, each one losing to the rung above -----------------------

@test "nothing to do: no output, exit 0, in every format" {
  commit_at "$P" 2026-11-03 x
  for f in --long --short --json; do
    run sh "$NX" "$f" "$P"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
  done
}

@test "rung 1: rebase in progress wins over uncommitted files, also in a linked worktree" {
  conflict
  W="$BATS_TEST_TMPDIR/wt"
  git -C "$P" worktree add -q "$W" topic
  run git -C "$W" rebase main
  [ "$status" -ne 0 ]
  [ -n "$(git -C "$W" status --porcelain)" ]
  run sh "$NX" "$W"
  [ "$output" = "Rebase in progress: git rebase --continue or git rebase --abort" ]
  run sh "$NX" --short "$W"
  [ "$output" = "rebase" ]
  run sh "$NX" --json "$W"
  [ "$(json_field rung)" = 1 ]
}

@test "rung 1: merge in progress" {
  conflict
  run git -C "$P" merge topic
  [ "$status" -ne 0 ]
  run sh "$NX" "$P"
  [ "$output" = "Merge in progress: git merge --continue or git merge --abort" ]
  run sh "$NX" --short "$P"
  [ "$output" = "merge" ]
}

@test "rung 2: done with docs impact open wins over another change that is done" {
  docs_open
  tasks c009-late 1 0
  echo "## Why" > "$C/c009-late/proposal.md"
  commit_at "$P" 2026-11-03 late
  run sh "$ROOT/skills/groma-methodology/scripts/status.sh" --root "$P"
  assert_output_contains "c009-late  1/1 tasks → verify, then archive"
  run sh "$NX" "$P"
  [ "$output" = "c007-cache: all tasks done, update docs/architecture.md or add a Docs: task line" ]
  run sh "$NX" --short "$P"
  [ "$output" = "docs c007" ]
  run sh "$NX" --json "$P"
  [ "$(json_field rung)" = 2 ]
}

@test "rung 2: done, docs clean, decision without ADR" {
  docs_open
  echo "Updated." >> "$P/docs/architecture.md"
  printf '### D1: Use Redis\nAlternatives: a map.\n' > "$C/c007-cache/design.md"
  commit_at "$P" 2026-11-03 design
  run sh "$NX" "$P"
  [ "$output" = "c007-cache: all tasks done, write a proposed ADR for c007-cache#D1" ]
}

@test "rung 3: all tasks done wins over uncommitted files (spec scenario short form)" {
  tasks c007-cache 3 0
  commit_at "$P" 2026-11-01 work
  echo y > "$P/src/a.js"
  run sh "$NX" --long "$P"
  [ "$output" = "c007-cache: all tasks done, verify: /opsx:verify c007-cache" ]
  run sh "$NX" --short "$P"
  [ "$output" = "verify c007" ]
  run sh "$NX" "$P"
  [ "$output" = "c007-cache: all tasks done, verify: /opsx:verify c007-cache" ]
}

@test "rung 3: no OpenSpec command for another methodology" {
  rm -rf "$P/openspec"
  C="$P/specs"
  tasks c007-cache 3 0
  commit_at "$P" 2026-11-01 work
  run sh "$NX" "$P"
  [ "$output" = "c007-cache: all tasks done, verify, then archive" ]
}

@test "rung 4: uncommitted files win over a milestone gate" {
  tasks m002-v0-2 1 0
  echo "- [ ] 2.1 Test levels green" >> "$C/m002-v0-2/tasks.md"
  commit_at "$P" 2026-11-03 x
  echo y > "$P/src/a.js"; echo n > "$P/src/b.js"
  run sh "$NX" "$P"
  [ "$output" = "2 files uncommitted: git add and git commit, or git stash" ]
  run sh "$NX" --short "$P"
  [ "$output" = "commit 2" ]
  run sh "$NX" --json "$P"
  [ "$(json_field rung)" = 4 ]
}

@test "rung 5: milestone gate wins over unpushed commits" {
  commit_at "$P" 2026-11-01 base
  upstream
  tasks m002-v0-2 1 0
  echo "- [ ] 2.1 Test levels green" >> "$C/m002-v0-2/tasks.md"
  commit_at "$P" 2026-11-03 x
  run sh "$NX" "$P"
  [ "$output" = "m002-v0-2: milestone gate: 2.1 Test levels green" ]
  run sh "$NX" --short "$P"
  [ "$output" = "gate m002" ]
  run sh "$NX" --json "$P"
  [ "$(json_field rung)" = 5 ]
}

@test "rung 6: unpushed before ADR (spec scenario), milestone with active children" {
  commit_at "$P" 2026-11-01 base
  upstream
  tasks m002-v0-2 1 2
  tasks c005-child 0 2
  printf 'Milestone: m002\n' > "$C/c005-child/proposal.md"
  proposed_adr 0015 c004-old
  commit_at "$P" 2026-11-02 setup
  unpushed 2
  run sh "$NX" "$P"
  [ "$output" = "Push 3 commits on main: git push" ]
  run sh "$NX" --short "$P"
  [ "$output" = "push 3" ]
  run sh "$NX" --json "$P"
  [ "$(json_field rung)" = 6 ]
  [ "$(json_field short)" = "push 3" ]
  [ "$(json_field long)" = "Push 3 commits on main: git push" ]
}

@test "git.push never skips rung 6" {
  groma_dir 'git:\n  push: never\n'
  commit_at "$P" 2026-11-01 base
  upstream
  proposed_adr 0015 c004-old
  commit_at "$P" 2026-11-02 adr
  run sh "$NX" "$P"
  [ "$output" = "ADR 0015 still proposed (c004-old archived): accept or reject" ]
}

@test "rung 7: proposed ADR of an archived change wins over an open change" {
  proposed_adr 0015 c004-old
  tasks c008-next 1 2
  commit_at "$P" 2026-11-03 x
  run sh "$NX" "$P"
  [ "$output" = "ADR 0015 still proposed (c004-old archived): accept or reject" ]
  run sh "$NX" --short "$P"
  [ "$output" = "adr 0015" ]
  run sh "$NX" --json "$P"
  [ "$(json_field rung)" = 7 ]
}

@test "rung 8: the open change with the newest commit, never a milestone" {
  tasks c001-old 1 2
  commit_at "$P" 2026-11-01 old
  tasks c002-new 2 3
  commit_at "$P" 2026-11-02 new
  tasks m001-mvp 1 1
  tasks c003-child 1 0
  printf 'Milestone: m001\n' > "$C/c003-child/proposal.md"
  mkdir -p "$P/.groma"
  printf 'reminders:\n  archive_when_done: false\n' > "$P/.groma/config.yaml"
  commit_at "$P" 2026-11-03 milestone
  run sh "$NX" "$P"
  [ "$output" = "c002-new: 2/5 tasks, continue: /opsx:apply c002-new" ]
  run sh "$NX" --short "$P"
  [ "$output" = "apply c002" ]
  run sh "$NX" --json "$P"
  [ "$(json_field rung)" = 8 ]
}

@test "rung 8 outside git: the first open change, no command for another methodology" {
  rm -rf "$P/.git" "$P/openspec"
  C="$P/specs"
  tasks c001-a 1 2
  tasks c002-b 0 2
  run sh "$NX" "$P"
  [ "$output" = "c001-a: 1/3 tasks" ]
}

# --- formats --------------------------------------------------------------------------

@test "--short is at most 20 characters, also for a long change id" {
  tasks changewithaverylongidentifier-x 2 0
  commit_at "$P" 2026-11-01 x
  run sh "$NX" --short "$P"
  [ "$output" = "verify changewithave" ]
  run sh "$NX" --json "$P"
  [ "$(json_field short)" = "verify changewithave" ]
}

@test "--json escapes quotes and backslashes" {
  tasks m002-v0-2 1 0
  echo '- [ ] 2.1 Say "hi" to C:\dir' >> "$C/m002-v0-2/tasks.md"
  commit_at "$P" 2026-11-03 x
  run sh "$NX" --json "$P"
  [ "$(json_field long)" = 'm002-v0-2: milestone gate: 2.1 Say "hi" to C:\dir' ]
  [ "$(printf '%s\n' "$output" | wc -l | tr -d ' ')" = 1 ]
}

@test "path defaults to the current directory, unknown argument exits 2" {
  tasks c007-cache 1 0
  commit_at "$P" 2026-11-01 x
  cd "$P"
  run sh "$NX" --short
  [ "$output" = "verify c007" ]
  run sh "$NX" --frobnicate
  [ "$status" -eq 2 ]
}

@test "works in a project path with spaces" {
  P="$BATS_TEST_TMPDIR/my project"
  make_repo "$P"
  C="$P/openspec/changes"
  groma_dir
  tasks c007-cache 1 0
  commit_at "$P" 2026-11-01 x
  run sh "$NX" --short "$P"
  [ "$output" = "verify c007" ]
  run sh "$NX" --short "$P"
  [ "$output" = "verify c007" ]
  [ -f "$P/.groma/.cache/next" ]
}

# --- cache ----------------------------------------------------------------------------

copy_scripts() { # a private copy whose status.sh can be replaced
  S="$BATS_TEST_TMPDIR/skill"
  mkdir -p "$S"
  cp -R "$ROOT/skills/groma-methodology/scripts" "$ROOT/skills/groma-methodology/templates" "$S/"
}

break_status() {
  printf '#!/bin/sh\necho "status.sh was called" >&2\necho "boom  1/1 tasks → verify, then archive"\nexit 1\n' > "$S/scripts/status.sh"
}

@test "cache hit does not call status.sh, in every format" {
  copy_scripts
  groma_dir
  tasks c007-cache 2 0
  commit_at "$P" 2026-11-01 x
  run sh "$S/scripts/next.sh" "$P"
  [ "$output" = "c007-cache: all tasks done, verify: /opsx:verify c007-cache" ]
  break_status
  run sh "$S/scripts/next.sh" "$P"
  [ "$output" = "c007-cache: all tasks done, verify: /opsx:verify c007-cache" ]
  run sh "$S/scripts/next.sh" --short "$P"
  [ "$output" = "verify c007" ]
  run sh "$S/scripts/next.sh" --json "$P"
  [ "$(json_field rung)" = 3 ]
  [ -z "$(git -C "$P" status --porcelain)" ]
}

@test "an empty result is cached too" {
  copy_scripts
  groma_dir
  commit_at "$P" 2026-11-01 x
  run sh "$S/scripts/next.sh" "$P"
  [ -z "$output" ]
  break_status
  run sh "$S/scripts/next.sh" "$P"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "cache miss after a commit and after a working-tree change" {
  groma_dir
  tasks c007-cache 1 1
  commit_at "$P" 2026-11-01 x
  run sh "$NX" --short "$P"
  [ "$output" = "apply c007" ]
  echo y > "$P/src/a.js"
  run sh "$NX" --short "$P"
  [ "$output" = "commit 1" ]
  commit_at "$P" 2026-11-02 y
  run sh "$NX" --short "$P"
  [ "$output" = "apply c007" ]
  tasks c007-cache 2 0
  commit_at "$P" 2026-11-03 done
  run sh "$NX" --short "$P"
  [ "$output" = "verify c007" ]
}

@test "cache miss after a push" {
  groma_dir
  commit_at "$P" 2026-11-01 base
  upstream
  unpushed 1
  run sh "$NX" "$P"
  [ "$output" = "Push 1 commits on main: git push" ]
  git -C "$P" push -q 2>/dev/null
  run sh "$NX" "$P"
  [ -z "$output" ]
}

@test "cache miss when a file in the changes folder is newer than the cache" {
  groma_dir
  echo "openspec/" >> "$P/.git/info/exclude"
  commit_at "$P" 2026-11-01 x
  tasks c007-cache 1 1
  touch -t 202001010000 "$C/c007-cache/tasks.md" "$C/c007-cache" "$C"
  run sh "$NX" --short "$P"
  [ "$output" = "apply c007" ]
  tasks c007-cache 2 0
  touch -t 202001010000 "$P/.groma/.cache/next"
  run sh "$NX" --short "$P"
  [ "$output" = "verify c007" ]
}

@test "rebase in progress is never served from the cache" {
  groma_dir
  conflict
  run sh "$NX" "$P"
  [ -z "$output" ]
  mkdir "$P/.git/rebase-merge"
  run sh "$NX" --short "$P"
  [ "$output" = "rebase" ]
  rmdir "$P/.git/rebase-merge"
  run sh "$NX" "$P"
  [ -z "$output" ]
}

@test "without .groma/ nothing is written into the project" {
  tasks c007-cache 2 0
  commit_at "$P" 2026-11-01 x
  sh "$NX" "$P" >/dev/null
  [ ! -e "$P/.groma" ]
  [ -z "$(git -C "$P" status --porcelain)" ]
}

@test "with .groma/ the cache ignores itself and leaves the working tree clean" {
  mkdir -p "$P/.groma"
  echo "schema: 1" > "$P/.groma/config.yaml"
  commit_at "$P" 2026-11-01 x
  run sh "$NX" "$P"
  [ -z "$output" ]
  [ -f "$P/.groma/.cache/next" ]
  [ "$(cat "$P/.groma/.cache/.gitignore")" = "*" ]
  [ ! -e "$P/.groma/.gitignore" ]
  [ -z "$(git -C "$P" status --porcelain)" ]
}

# --- Stop hook wrapper ------------------------------------------------------------------

hook_on() { # [reshow_minutes line]
  groma_dir "next:\n  hook: on\n${1:-}"
}

only_system_message() { # $output is one JSON object with the single key systemMessage
  [ "$(printf '%s\n' "$output" | wc -l | tr -d ' ')" = 1 ]
  [ "$(printf '%s' "$output" | node -e 'let s = ""; process.stdin.on("data", d => s += d).on("end", () => {
    const o = JSON.parse(s); process.stdout.write(Object.keys(o).join(",") + "=" + o.systemMessage); })')" = "systemMessage=$1" ]
  assert_output_not_contains decision
}

@test "stop hook: first show, same line suppressed, changed line shown" {
  hook_on
  tasks c007-cache 1 1
  commit_at "$P" 2026-11-01 x
  run sh "$STOP" --now 1000000 "$P"
  [ "$status" -eq 0 ]
  only_system_message "▶ Next: c007-cache: 1/2 tasks, continue: /opsx:apply c007-cache"
  run sh "$STOP" --now 1000060 "$P"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  tasks c007-cache 2 0
  commit_at "$P" 2026-11-02 done
  run sh "$STOP" --now 1000120 "$P"
  only_system_message "▶ Next: c007-cache: all tasks done, verify: /opsx:verify c007-cache"
  [ -z "$(git -C "$P" status --porcelain)" ]
}

@test "stop hook: reshow after reshow_minutes, default 30" {
  hook_on
  tasks c007-cache 2 0
  commit_at "$P" 2026-11-01 x
  run sh "$STOP" --now 1000000 "$P"
  [ -n "$output" ]
  run sh "$STOP" --now 1001799 "$P"
  [ -z "$output" ]
  run sh "$STOP" --now 1001800 "$P"
  only_system_message "▶ Next: c007-cache: all tasks done, verify: /opsx:verify c007-cache"
  run sh "$STOP" --now 1001900 "$P"
  [ -z "$output" ]
}

@test "stop hook: reshow_minutes from the config, a non-number falls back to 30" {
  hook_on '  reshow_minutes: 5\n'
  tasks c007-cache 2 0
  commit_at "$P" 2026-11-01 x
  run sh "$STOP" --now 1000000 "$P"
  [ -n "$output" ]
  run sh "$STOP" --now 1000299 "$P"
  [ -z "$output" ]
  run sh "$STOP" --now 1000300 "$P"
  [ -n "$output" ]
  hook_on '  reshow_minutes: soon\n'
  commit_at "$P" 2026-11-02 cfg
  run sh "$STOP" --now 1000900 "$P"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  run sh "$STOP" --now 1002100 "$P"
  [ -n "$output" ]
}

@test "stop hook: reshow_minutes 0 shows only on change" {
  hook_on '  reshow_minutes: 0\n'
  tasks c007-cache 2 0
  commit_at "$P" 2026-11-01 x
  run sh "$STOP" --now 1000000 "$P"
  [ -n "$output" ]
  run sh "$STOP" --now 9000000 "$P"
  [ -z "$output" ]
}

@test "stop hook: an empty result clears the state" {
  hook_on
  commit_at "$P" 2026-11-01 x
  echo y > "$P/src/a.js"
  run sh "$STOP" --now 1000000 "$P"
  only_system_message "▶ Next: 1 files uncommitted: git add and git commit, or git stash"
  [ -f "$P/.groma/.cache/next-shown" ]
  commit_at "$P" 2026-11-02 y
  run sh "$STOP" --now 1000060 "$P"
  [ -z "$output" ]
  [ ! -e "$P/.groma/.cache/next-shown" ]
  echo z > "$P/src/a.js"
  run sh "$STOP" --now 1000120 "$P"
  only_system_message "▶ Next: 1 files uncommitted: git add and git commit, or git stash"
}

@test "stop hook: silent when next.hook is off or missing, and never fails" {
  tasks c007-cache 2 0
  groma_dir 'next:\n  hook: off\n'
  commit_at "$P" 2026-11-01 x
  run sh "$STOP" --now 1000000 "$P"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  groma_dir 'schema: 1\n'
  commit_at "$P" 2026-11-02 cfg
  run sh "$STOP" --now 1000000 "$P"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ ! -e "$P/.groma/.cache/next-shown" ]
  run sh "$STOP" --frobnicate "$BATS_TEST_TMPDIR/nowhere"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "stop hook: message is JSON-escaped and stdin is ignored" {
  hook_on
  tasks m002-v0-2 1 0
  echo '- [ ] 2.1 Say "hi" to C:\dir' >> "$C/m002-v0-2/tasks.md"
  commit_at "$P" 2026-11-03 x
  output=$(echo '{"stop_hook_active":true}' | sh "$STOP" --now 1000000 "$P")
  only_system_message '▶ Next: m002-v0-2: milestone gate: 2.1 Say "hi" to C:\dir'
}

@test "stop hook --stderr: plain line on stderr with exit 2, suppressed repeat is silent, stdout stays empty" {
  hook_on
  tasks c007-cache 2 0
  commit_at "$P" 2026-11-01 x
  run --separate-stderr sh "$STOP" --stderr --now 1000000 "$P"
  [ "$status" -eq 2 ]
  [ -z "$output" ]
  [ "$stderr" = "▶ Next: c007-cache: all tasks done, verify: /opsx:verify c007-cache" ]
  run --separate-stderr sh "$STOP" --stderr --now 1000060 "$P"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ -z "$stderr" ]
  run --separate-stderr sh "$STOP" --now 1001800 --stderr "$P"
  [ "$status" -eq 2 ]
  [ -z "$output" ]
  [ -n "$stderr" ]
}

@test "stop hook --stderr: silent with exit 0 when there is no next action or the hook is off" {
  hook_on
  commit_at "$P" 2026-11-01 x
  run --separate-stderr sh "$STOP" --stderr --now 1000000 "$P"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ -z "$stderr" ]
  groma_dir 'next:\n  hook: off\n'
  echo y > "$P/src/a.js"
  run --separate-stderr sh "$STOP" --stderr --now 1000000 "$P"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ -z "$stderr" ]
}

@test "stop hook template runs the wrapper on Stop for the project folder" {
  T="$ROOT/skills/groma-agents/templates/claude-stop-hook.json"
  [ "$(node -e 'const h = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).hooks;
    process.stdout.write(Object.keys(h).join(",") + " " + h.Stop[0].hooks[0].command)' "$T")" \
    = 'Stop sh "{{next_stop_script_absolute}}" "$CLAUDE_PROJECT_DIR" || true' ]
}

@test "stop hook command exits 0 even when the script is gone (dash exits 2 on a missing file)" {
  for shell in sh dash; do
    command -v "$shell" >/dev/null || continue
    run "$shell" -c 'sh "/nonexistent/next-stop.sh" "/tmp" || true'
    [ "$status" -eq 0 ]
  done
}

@test "stop hook: reshow_minutes with a leading zero is decimal and never fails" {
  groma_dir 'next:\n  hook: on\n  reshow_minutes: 08\n'
  tasks c001-a 1 1
  commit_at "$P" 2026-11-01 x
  for shell in sh dash; do
    command -v "$shell" >/dev/null || continue
    rm -f "$P/.groma/.cache/next-shown"
    run "$shell" "$STOP" --now 1000 "$P"
    [ "$status" -eq 0 ]; [ -n "$output" ]
    run "$shell" "$STOP" --now 1400 "$P"
    [ "$status" -eq 0 ]; [ -z "$output" ]
    run "$shell" "$STOP" --now 1480 "$P"
    [ "$status" -eq 0 ]; [ -n "$output" ]
  done
}

# --- review round 1 -------------------------------------------------------------------

@test "cache miss after a change to an ignored config" {
  groma_dir 'git:\n  push: ask\n'
  printf '.groma/\n' > "$P/.git/info/exclude"
  tasks c001-a 1 1
  commit_at "$P" 2026-11-01 base
  git init -q --bare "$BATS_TEST_TMPDIR/r.git"
  git -C "$P" remote add origin "$BATS_TEST_TMPDIR/r.git"
  git -C "$P" push -q -u origin main 2>/dev/null
  echo 1 > "$P/src/a.js"; commit_at "$P" 2026-11-02 one
  run sh "$NX" --short "$P"
  [ "$output" = "push 1" ]
  printf 'git:\n  push: never\n' > "$P/.groma/config.yaml"
  run sh "$NX" --short "$P"
  [ "$output" = "apply c001" ]
}

@test "stop hook keeps its state before the first commit" {
  P="$BATS_TEST_TMPDIR/fresh"
  make_repo "$P"
  mkdir -p "$P/.groma"
  printf 'next:\n  hook: on\n' > "$P/.groma/config.yaml"
  C="$P/openspec/changes"
  tasks c001-a 0 1
  run sh "$STOP" --now 1000 "$P"
  [ -n "$output" ]
  run sh "$STOP" --now 1060 "$P"
  [ -z "$output" ]
}

@test "status-line snippet prints the pill for the session's project directory" {
  tasks c001-a 1 1
  commit_at "$P" 2026-11-01 base
  sed "s|{{next_script_absolute}}|$NX|g" "$ROOT/skills/groma-agents/templates/statusline-snippet.sh" > "$BATS_TEST_TMPDIR/sl.sh"
  run sh "$BATS_TEST_TMPDIR/sl.sh" <<JSON
{"cwd":"$P/src","workspace":{"current_dir":"$P/src","project_dir":"$P"}}
JSON
  [ "$output" = "▶ apply c001" ]
  rm -rf "$C/c001-a"; commit_at "$P" 2026-11-02 done
  run sh "$BATS_TEST_TMPDIR/sl.sh" <<JSON
{"workspace":{"current_dir":"$P","project_dir":"$P"}}
JSON
  [ -z "$output" ]
}

@test "--json stays valid JSON when the text contains a tab" {
  tasks m001-mvp 1 0
  printf -- '- [ ] 2.1 Run\tthe "gate" \\ now\n' >> "$C/m001-mvp/tasks.md"
  commit_at "$P" 2026-11-01 x
  run sh "$NX" --json "$P"
  node -e 'const j = JSON.parse(process.argv[1]); if (j.rung !== 5) process.exit(1)' "$output"
}
