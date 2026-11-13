#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load helpers

SESSION="$ROOT/skills/groma-methodology/scripts/next-session.sh"
STOP="$ROOT/skills/groma-methodology/scripts/next-stop.sh"
HOOKS="$ROOT/hooks/hooks.json"
LINE="1 files uncommitted: git add and git commit, or git stash"

setup() {
  # a throwaway home: the global flag file is read from $HOME/.claude/
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  P="$BATS_TEST_TMPDIR/p"
  make_repo "$P"
  mkdir -p "$P/src"
  echo x > "$P/src/a.js"
  commit_at "$P" 2026-11-01 base
  printf '.groma/\n' > "$P/.git/info/exclude"
  echo y > "$P/src/a.js"            # one uncommitted file: rung 4
}

config() { # body of .groma/config.yaml, printf escapes allowed
  mkdir -p "$P/.groma"
  printf '%b' "$1" > "$P/.groma/config.yaml"
}

flag() { mkdir -p "$HOME/.claude" && : > "$HOME/.claude/.groma-next-always"; }

context() { # $output is one JSON object: prints "<keys>|<event>|<additionalContext>"
  printf '%s' "$output" | node -e 'let s = ""; process.stdin.on("data", d => s += d).on("end", () => {
    const o = JSON.parse(s); const h = o.hookSpecificOutput;
    process.stdout.write(Object.keys(o).join(",") + "|" + h.hookEventName + "|" + h.additionalContext); })'
}

fastest_ms() { # command...: the fastest of five runs, in whole milliseconds
  node -e 'const { spawnSync } = require("child_process");
    let best = Infinity;
    for (let i = 0; i < 5; i++) {
      const t = process.hrtime.bigint();
      spawnSync(process.argv[1], process.argv.slice(2), { stdio: "ignore" });
      best = Math.min(best, Number(process.hrtime.bigint() - t) / 1e6);
    }
    process.stdout.write(String(Math.ceil(best)));' "$@"
}

hook_command() { # event: the command of that event in the plugin's hooks.json
  node -e 'const h = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).hooks;
    process.stdout.write(h[process.argv[2]][0].hooks[0].command)' "$HOOKS" "$1"
}

# --- SessionStart wrapper -----------------------------------------------------------------

@test "session start: prints the long line as additionalContext when on" {
  config 'next:\n  hook: on\n'
  run --separate-stderr sh "$SESSION" "$P"
  [ "$status" -eq 0 ]
  [ -z "$stderr" ]
  [ "$(printf '%s\n' "$output" | wc -l | tr -d ' ')" = 1 ]
  got=$(context)
  [ "${got%%|*}" = hookSpecificOutput ]
  case "$got" in "hookSpecificOutput|SessionStart|"*"$LINE") ;; *) echo "$got"; false ;; esac
  assert_output_not_contains systemMessage
  assert_output_not_contains decision
}

@test "session start: the project defaults to CLAUDE_PROJECT_DIR, then to the current directory" {
  config 'next:\n  hook: on\n'
  CLAUDE_PROJECT_DIR="$P" run sh "$SESSION"
  assert_output_contains "$LINE"
  CLAUDE_PROJECT_DIR="$P" run sh "$SESSION" ""
  assert_output_contains "$LINE"
  cd "$P"
  run env -u CLAUDE_PROJECT_DIR sh "$SESSION"
  assert_output_contains "$LINE"
}

@test "session start: shown again on every start, no debounce state" {
  config 'next:\n  hook: on\n'
  run sh "$SESSION" "$P"
  assert_output_contains "$LINE"
  run sh "$SESSION" "$P"
  assert_output_contains "$LINE"
  [ ! -e "$P/.groma/.cache/next-shown" ]
}

@test "session start: nothing without .groma/, even with the flag file" {
  flag
  run --separate-stderr sh "$SESSION" "$P"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ -z "$stderr" ]
  [ ! -e "$P/.groma" ]
}

@test "session start: nothing when next.hook is off, even with the flag file" {
  flag
  config 'next:\n  hook: off\n'
  run --separate-stderr sh "$SESSION" "$P"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ -z "$stderr" ]
  [ ! -e "$P/.groma/.cache" ]
}

@test "session start: nothing when there is no next action" {
  config 'next:\n  hook: on\n'
  git -C "$P" checkout -q -- src/a.js
  run sh "$SESSION" "$P"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "session start: the context is JSON-escaped and stdin is ignored" {
  config 'next:\n  hook: on\n'
  git -C "$P" checkout -q -- src/a.js
  mkdir -p "$P/openspec/changes/m002-v0-2"
  printf -- '- [x] 1 done\n- [ ] 2.1 Say "hi" to C:\\dir\n' > "$P/openspec/changes/m002-v0-2/tasks.md"
  commit_at "$P" 2026-11-02 gate
  output=$(echo '{"source":"startup","cwd":"/elsewhere"}' | sh "$SESSION" "$P")
  got=$(context)
  case "$got" in *'m002-v0-2: milestone gate: 2.1 Say "hi" to C:\dir') ;; *) echo "$got"; false ;; esac
}

@test "session start: never fails, also for an unknown option or a missing project" {
  run sh "$SESSION" --frobnicate "$BATS_TEST_TMPDIR/nowhere"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- on/off: the project wins, unset or auto follows the global flag file ---------------------

@test "on/off table: project on, off, auto, unset, by flag file present or absent" {
  # config body | flag | expected
  while IFS='|' read -r body flag want; do
    rm -rf "$HOME/.claude" "$P/.groma"
    [ "$flag" = absent ] || flag
    config "$body"
    run sh "$SESSION" "$P"
    [ "$status" -eq 0 ]
    session=off; [ -z "$output" ] || session=on
    run sh "$STOP" --now 1000000 "$P"
    [ "$status" -eq 0 ]
    stop=off; [ -z "$output" ] || stop=on
    if [ "$session" != "$want" ] || [ "$stop" != "$want" ]; then
      echo "config '$body' flag $flag: want $want, session $session, stop $stop"
      return 1
    fi
  done <<'TABLE'
next:\n  hook: on\n|absent|on
next:\n  hook: on\n|present|on
next:\n  hook: off\n|absent|off
next:\n  hook: off\n|present|off
next:\n  hook: auto\n|absent|off
next:\n  hook: auto\n|present|on
next:\n  reshow_minutes: 30\n|absent|off
next:\n  reshow_minutes: 30\n|present|on
next:\n  # hook: on\n  reshow_minutes: 30\n|present|on
schema: 1\n|absent|off
schema: 1\n|present|on
next:\n  hook: maybe\n|present|off
TABLE
}

@test "on/off: an empty .groma/ without a config follows the flag file" {
  mkdir -p "$P/.groma"
  run sh "$SESSION" "$P"
  [ -z "$output" ]
  flag
  run sh "$SESSION" "$P"
  assert_output_contains "$LINE"
}

@test "on/off: the flag file is only read, never created or removed" {
  config 'next:\n  hook: on\n'
  sh "$SESSION" "$P" >/dev/null
  sh "$STOP" --now 1000000 "$P" >/dev/null
  [ ! -e "$HOME/.claude" ]
  flag
  config 'next:\n  hook: off\n'
  sh "$SESSION" "$P" >/dev/null
  sh "$STOP" --now 1000000 "$P" >/dev/null
  [ -f "$HOME/.claude/.groma-next-always" ]
  [ "$(ls -A "$HOME/.claude")" = .groma-next-always ]
}

@test "on/off: no HOME means no flag file" {
  config 'schema: 1\n'
  run env -u HOME sh "$SESSION" "$P"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- fast path: a plugin hook runs in every project ------------------------------------------

@test "fast path: both hooks return within 50 ms and print nothing without .groma/" {
  flag
  for script in "$SESSION" "$STOP"; do
    run --separate-stderr sh "$script" "$P"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    [ -z "$stderr" ]
    ms=$(fastest_ms sh "$script" "$P")
    echo "# ${script##*/} without .groma/: $ms ms" >&3
    [ "$ms" -lt 50 ]
  done
}

@test "fast path: the Stop hook writes no state when the next action is off" {
  config 'next:\n  hook: off\n'
  run sh "$STOP" --now 1000000 "$P"
  [ -z "$output" ]
  [ ! -e "$P/.groma/.cache" ]
}

# --- the plugin's hooks.json ---------------------------------------------------------------

@test "hooks.json: SessionStart for startup, resume, clear and compact, and Stop" {
  [ "$(node -e 'const h = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).hooks;
    process.stdout.write(Object.keys(h).sort().join(",") + " " + h.SessionStart[0].matcher + " " + String(h.Stop[0].matcher))' "$HOOKS")" \
    = 'SessionStart,Stop startup|resume|clear|compact undefined' ]
}

@test "hooks.json: the commands run from the plugin folder for the project folder" {
  flag
  config 'schema: 1\n'
  cd "$BATS_TEST_TMPDIR"
  run env CLAUDE_PLUGIN_ROOT="$ROOT" CLAUDE_PROJECT_DIR="$P" sh -c "$(hook_command SessionStart)"
  [ "$status" -eq 0 ]
  case "$(context)" in "hookSpecificOutput|SessionStart|"*"$LINE") ;; *) echo "$output"; false ;; esac
  run env CLAUDE_PLUGIN_ROOT="$ROOT" CLAUDE_PROJECT_DIR="$P" sh -c "$(hook_command Stop)"
  [ "$status" -eq 0 ]
  [ "$output" = "{\"systemMessage\":\"▶ Next: $LINE\"}" ]
}

@test "hooks.json: the commands are silent and exit 0 without .groma/ and when the scripts are gone" {
  flag
  for event in SessionStart Stop; do
    run env CLAUDE_PLUGIN_ROOT="$ROOT" CLAUDE_PROJECT_DIR="$P" sh -c "$(hook_command "$event")"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    run --separate-stderr env CLAUDE_PLUGIN_ROOT=/nonexistent CLAUDE_PROJECT_DIR="$P" sh -c "$(hook_command "$event")"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
  done
}

# --- status-line pill (snippet only) --------------------------------------------------------

pill() { # pattern: the template's last line with the pattern filled in, run for $P
  line=$(tail -n 1 "$ROOT/skills/groma-agents/templates/statusline-pill.sh")
  line=${line%%"{{next_script_pattern}}"*}$1${line#*"{{next_script_pattern}}"}
  project_dir="$P" sh -c "$line"
}

@test "pill: one colored pill with the short action, nothing without a next action" {
  nx="$ROOT/skills/groma-methodology/scripts/next.sh"
  run pill "\"$nx\""
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf ' \033[48;5;25m\033[38;5;255m ▶ commit 1 \033[0m')" ]
  git -C "$P" checkout -q -- src/a.js
  run pill "\"$nx\""
  [ -z "$output" ]
}

@test "pill: a * for the plugin's version folder finds the script, a missing script prints nothing" {
  cache="$BATS_TEST_TMPDIR/my home/plugins/cache/groma/groma"
  mkdir -p "$cache/0.3.0/skills/groma-methodology"
  cp -R "$ROOT/skills/groma-methodology/scripts" "$cache/0.3.0/skills/groma-methodology/scripts"
  run pill "\"$cache/\"*\"/skills/groma-methodology/scripts/next.sh\""
  assert_output_contains "▶ commit 1"
  rm -rf "$cache/0.3.0"
  run --separate-stderr pill "\"$cache/\"*\"/skills/groma-methodology/scripts/next.sh\""
  [ -z "$output" ]
  [ -z "$stderr" ]
}

@test "pill: the template is a snippet whose last line is the only code" {
  T="$ROOT/skills/groma-agents/templates/statusline-pill.sh"
  [ "$(grep -vc '^#' "$T")" -eq 1 ]
  tail -n 1 "$T" | grep -q -- '--short'
}
