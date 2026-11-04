#!/usr/bin/env bats
# review.sh and resolve-reviewer.sh with stub agent CLIs.

load helpers

R="$ROOT/skills/groma-loop/scripts/review.sh"
RR="$ROOT/skills/groma-loop/scripts/resolve-reviewer.sh"

GOOD='| id | severity | location | finding | suggestion |
|---|---|---|---|---|
| R1 | high | src/a.js:3 | null not handled | add a guard |'

setup() {
  B="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$B"
  for t in sh awk sed cut head tail tr cat grep date mkdir rm wc sleep kill printf env dirname mktemp; do
    p=$(command -v "$t") && ln -sf "$p" "$B/$t"
  done
  export STUB_LOG="$BATS_TEST_TMPDIR/calls.log"
  : > "$STUB_LOG"
  PROMPT="$BATS_TEST_TMPDIR/prompt.md"
  echo "Review this change." > "$PROMPT"
  OUT="$BATS_TEST_TMPDIR/review.md"
}

# stub <name> <reply>: CLI that logs its args and prints <reply>;
# a probe prompt (contains "single word OK") always gets "OK".
stub() {
  reply_file="$BATS_TEST_TMPDIR/$1.reply"
  printf '%s\n' "$2" > "$reply_file"
  cat > "$B/$1" <<EOF
#!/bin/sh
echo "$1 \$*" >> "\$STUB_LOG"
case "\$*" in *"single word OK"*) echo OK; exit 0 ;; esac
cat "$reply_file"
EOF
  chmod +x "$B/$1"
}

# failing stub: not logged in
stub_fail() {
  printf '#!/bin/sh\necho "%s $*" >> "$STUB_LOG"\necho "please log in" >&2\nexit 1\n' "$1" > "$B/$1"
  chmod +x "$B/$1"
}

run_r() { run env PATH="$B" sh "$R" "$@"; }
run_rr() { run env PATH="$B" sh "$RR" "$@"; }

# --- review.sh -------------------------------------------------------------------

@test "claude reviewer runs read-only with model" {
  stub claude "$GOOD"
  run_r claude:sonnet "$PROMPT" "$OUT"
  [ "$status" -eq 0 ]
  grep -q -- "--permission-mode plan" "$STUB_LOG"
  grep -q -- "--model sonnet" "$STUB_LOG"
  grep -q "^reviewer: claude:sonnet" "$OUT"
  grep -q "| R1 | high |" "$OUT"
}

@test "gemini, copilot and codex get their headless flags" {
  stub gemini "$GOOD"; stub copilot "$GOOD"; stub codex "$GOOD"
  run_r gemini:gemini-2.5-pro "$PROMPT" "$OUT"
  grep -q -- "gemini -p .* -m gemini-2.5-pro" "$STUB_LOG"
  run_r copilot "$PROMPT" "$OUT"
  grep -q -- "copilot -p" "$STUB_LOG"
  ! grep -q -- "--allow-all-tools" "$STUB_LOG"
  run_r codex "$PROMPT" "$OUT"
  grep -q -- "codex exec --sandbox read-only" "$STUB_LOG"
}

@test "NO FINDINGS is a valid answer" {
  stub claude "NO FINDINGS"
  run_r claude "$PROMPT" "$OUT"
  [ "$status" -eq 0 ]
  grep -q "^status: ok" "$OUT"
  grep -q "^NO FINDINGS" "$OUT"
}

@test "malformed answer is retried once with a format reminder" {
  stub claude "I think it is fine overall."
  # second call returns a good table
  cat > "$B/claude" <<EOF
#!/bin/sh
echo "claude \$*" >> "\$STUB_LOG"
n=\$(grep -c '^claude' "\$STUB_LOG")
if [ "\$n" -ge 2 ]; then printf '%s\n' "$GOOD"; else echo "looks fine"; fi
EOF
  chmod +x "$B/claude"
  run_r claude "$PROMPT" "$OUT"
  [ "$status" -eq 0 ]
  [ "$(grep -c '^claude' "$STUB_LOG")" -eq 2 ]
  grep -q "^status: retried" "$OUT"
  grep -q "FORMAT REMINDER" "$STUB_LOG"
}

@test "twice malformed becomes one medium 'unparseable review' finding" {
  stub claude "Looks fine, ship it."
  run_r claude "$PROMPT" "$OUT"
  [ "$status" -eq 0 ]
  grep -q "^status: unparseable" "$OUT"
  grep -q "| R1 | medium | - | unparseable review |" "$OUT"
  grep -q "Looks fine, ship it." "$OUT"
}

@test "invalid severity counts as malformed" {
  stub claude '| id | severity | location | finding | suggestion |
|---|---|---|---|---|
| R1 | critical | a | b | c |'
  run_r claude "$PROMPT" "$OUT"
  grep -q "^status: unparseable" "$OUT"
}

@test "failing CLI exits non-zero" {
  stub_fail claude
  run_r claude "$PROMPT" "$OUT"
  [ "$status" -eq 5 ]
}

@test "self cannot be run by the script" {
  run_r self "$PROMPT" "$OUT"
  [ "$status" -eq 4 ]
  assert_output_contains "fresh context"
}

@test "probe succeeds and fails" {
  stub gemini "$GOOD"
  run_r --probe gemini
  [ "$status" -eq 0 ]
  stub_fail codex
  run_r --probe codex
  [ "$status" -ne 0 ]
  run_r --probe copilot
  [ "$status" -ne 0 ]
}

# --- resolve-reviewer.sh -----------------------------------------------------------

@test "auto: another vendor's CLI wins" {
  stub claude "$GOOD"; stub gemini "$GOOD"
  run_rr claude
  [ "$status" -eq 0 ]
  assert_output_contains "reviewer=gemini"
  assert_output_contains "kind=other-vendor"
}

@test "auto: vendor order prefers codex, then gemini, then copilot" {
  stub claude "$GOOD"; stub gemini "$GOOD"; stub codex "$GOOD"; stub copilot "$GOOD"
  run_rr claude
  assert_output_contains "reviewer=codex"
}

@test "auto: probe failure falls back to the next vendor" {
  stub claude "$GOOD"; stub_fail codex; stub copilot "$GOOD"
  run_rr claude
  assert_output_contains "reviewer=copilot"
  assert_output_contains "codex: probe failed"
}

@test "auto: no other vendor gives claude another model" {
  stub claude "$GOOD"
  run_rr claude --author-model opus
  assert_output_contains "reviewer=claude:sonnet"
  assert_output_contains "kind=other-model"
  run_rr claude --author-model sonnet
  assert_output_contains "reviewer=claude:opus"
}

@test "auto: nothing available is a marked self-review" {
  run_rr copilot
  assert_output_contains "reviewer=self"
  assert_output_contains "kind=self-review"
}

@test "pinned reviewer from config is used" {
  stub claude "$GOOD"; stub gemini "$GOOD"; stub copilot "$GOOD"
  C="$BATS_TEST_TMPDIR/config.yaml"
  cat > "$C" <<'EOF'
review:
  mode: autonomous
  propose:
    reviewer: copilot:gpt-5
  apply:
    reviewer: auto
EOF
  run_rr claude --phase propose --config "$C"
  assert_output_contains "reviewer=copilot:gpt-5"
  assert_output_contains "kind=pinned"
  run_rr claude --phase apply --config "$C"
  assert_output_contains "reviewer=gemini"
}

@test "pinned reviewer that fails falls back and says why" {
  stub claude "$GOOD"; stub gemini "$GOOD"
  C="$BATS_TEST_TMPDIR/config.yaml"
  printf 'review:\n  apply:\n    reviewer: codex\n' > "$C"
  run_rr claude --phase apply --config "$C"
  assert_output_contains "reviewer=gemini"
  assert_output_contains "pinned codex: probe failed"
}

@test "pinned self is honored" {
  C="$BATS_TEST_TMPDIR/config.yaml"
  printf 'review:\n  propose:\n    reviewer: self\n' > "$C"
  run_rr claude --phase propose --config "$C"
  assert_output_contains "reviewer=self"
  assert_output_contains "kind=self-review"
}
