#!/usr/bin/env bats
# effect.sh compares one task with and without groma's setup (c013). No test
# calls a model: the comparison loop runs against a stub `claude` that prints
# canned results, with GROMA_EFFECT_SETUP standing in for the /groma setup.
# HOME is a temporary folder, so no user-level skill is seen.

load helpers

S="$ROOT/tests/evals/effect.sh"
TAB=$(printf '\t')

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  unset CLAUDE_CONFIG_DIR GROMA_EVAL_ALLOW_USER_SKILLS GROMA_EFFECT_SETUP GROMA_EVAL_MODEL
  export GROMA_EVAL_DIR="$BATS_TEST_TMPDIR/work" GROMA_EVAL_REPORTS="$BATS_TEST_TMPDIR/reports"
  STUB="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$STUB"
}

# canned `claude -p --output-format json` result
result() { # file subtype cost turns model
  printf '{"type":"result","subtype":"%s","is_error":false,"duration_ms":30000,"num_turns":%s,"total_cost_usd":%s,"usage":{"input_tokens":10,"output_tokens":100,"cache_read_input_tokens":1000,"cache_creation_input_tokens":50},"modelUsage":{"%s":{"inputTokens":10,"outputTokens":100,"cacheReadInputTokens":1000,"cacheCreationInputTokens":50}},"permission_denials":[]}\n' \
    "$2" "$4" "$3" "$5" > "$1"
}

# stub claude: counts its calls; prints canned/<side>-<call>.json when present,
# else canned/<side>.json; the "with" side is the copy that holds WITH
stub_claude() {
  mkdir -p "$BATS_TEST_TMPDIR/canned"
  cat > "$STUB/claude" <<'SH'
#!/bin/sh
c="$BATS_TEST_TMPDIR/canned"
n=$(cat "$c/calls" 2>/dev/null || echo 0); n=$((n + 1)); echo "$n" > "$c/calls"
if [ -f WITH ]; then side=with; else side=without; fi
[ -f "$c/hook-$n" ] && sh "$c/hook-$n"
if [ -f "$c/$side-$n.json" ]; then cat "$c/$side-$n.json"; else cat "$c/$side.json"; fi
SH
  chmod +x "$STUB/claude"
  # go and gofmt for the prerequisite check; the acceptance test then fails the build
  printf '#!/bin/sh\nexit 1\n' > "$STUB/go"; cp "$STUB/go" "$STUB/gofmt"; chmod +x "$STUB/go" "$STUB/gofmt"
  result "$BATS_TEST_TMPDIR/canned/without.json" success 0.1 8 model-a
  result "$BATS_TEST_TMPDIR/canned/with.json" success 0.5 30 model-a
  # the set-up project stands in for /groma
  sh "$ROOT/tests/fixtures/generate.sh" "$BATS_TEST_TMPDIR/setup" go-no-db >/dev/null
  : > "$BATS_TEST_TMPDIR/setup/go-no-db/WITH"
  export GROMA_EFFECT_SETUP="$BATS_TEST_TMPDIR/setup/go-no-db"
}

# effect report with the header and the given run rows (fields separated by spaces)
runs() { # file rows...
  f=$1; shift
  printf 'side\trun\tinput_tokens\toutput_tokens\tcache_read_tokens\tcache_write_tokens\tcost_usd\tturns\tduration_s\tpass\n' > "$f"
  for r in "$@"; do printf '%s\n' "$r" | tr ' ' '\t' >> "$f"; done
}

@test "summary prints median, min and max per side, pass rate and the difference" {
  runs "$BATS_TEST_TMPDIR/e.tsv" \
    "without 1 10 100 1000 50 0.5000 10 60 pass" \
    "without 2 30 300 3000 70 0.7000 14 80 fail" \
    "without 3 20 200 2000 60 0.6000 12 70 pass" \
    "with 1 5 50 500 44 0.3000 6 40 pass" \
    "with 2 7 70 700 46 0.5000 8 50 pass" \
    "with 3 - - - - - - - fail"
  run sh "$S" summary "$BATS_TEST_TMPDIR/e.tsv"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "without${TAB}median${TAB}20${TAB}200${TAB}2000${TAB}60${TAB}0.6000${TAB}12${TAB}70${TAB}2/3" ]
  [ "${lines[1]}" = "without${TAB}min${TAB}10${TAB}100${TAB}1000${TAB}50${TAB}0.5000${TAB}10${TAB}60${TAB}-" ]
  [ "${lines[2]}" = "without${TAB}max${TAB}30${TAB}300${TAB}3000${TAB}70${TAB}0.7000${TAB}14${TAB}80${TAB}-" ]
  [ "${lines[3]}" = "with${TAB}median${TAB}6${TAB}60${TAB}600${TAB}45${TAB}0.4000${TAB}7${TAB}45${TAB}2/3" ]
  [ "${lines[4]}" = "with${TAB}min${TAB}5${TAB}50${TAB}500${TAB}44${TAB}0.3000${TAB}6${TAB}40${TAB}-" ]
  [ "${lines[5]}" = "with${TAB}max${TAB}7${TAB}70${TAB}700${TAB}46${TAB}0.5000${TAB}8${TAB}50${TAB}-" ]
  [ "${lines[6]}" = "difference${TAB}median${TAB}-14${TAB}-140${TAB}-1400${TAB}-15${TAB}-0.2000${TAB}-5${TAB}-25${TAB}+0" ]
  [ "${#lines[@]}" -eq 7 ]
}

@test "summary gives - for a side without any result" {
  runs "$BATS_TEST_TMPDIR/e.tsv" \
    "without 1 10 100 1000 50 0.5000 10 60 pass" \
    "with 1 - - - - - - - fail"
  run sh "$S" summary "$BATS_TEST_TMPDIR/e.tsv"
  [ "$status" -eq 0 ]
  [ "${lines[3]}" = "with${TAB}median${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}0/1" ]
  [ "${lines[6]}" = "difference${TAB}median${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-1" ]
}

@test "fewer than three runs per side is refused" {
  GROMA_EFFECT_RUNS=2 run sh "$S"
  [ "$status" -eq 2 ]
  assert_output_contains "at least 3"
}

@test "the maximum cost is stated before the claude CLI is needed" {
  PATH=/usr/bin:/bin GROMA_EFFECT_RUNS=4 GROMA_EFFECT_BUDGET=0.5 GROMA_EVAL_BUDGET=2 run sh "$S"
  [ "$status" -eq 3 ]
  assert_output_contains "max cost USD 6.00"
  assert_output_contains "claude CLI not found"
}

@test "an unknown fixture is refused" {
  run sh "$S" no-such-fixture
  [ "$status" -eq 2 ]
  assert_output_contains "no effect task"
}

@test "the go-no-db acceptance test fails on the untouched fixture" {
  command -v go >/dev/null 2>&1 || skip "go not installed"
  sh "$ROOT/tests/fixtures/generate.sh" "$BATS_TEST_TMPDIR" go-no-db >/dev/null
  run sh "$ROOT/tests/evals/effect/go-no-db.sh" "$BATS_TEST_TMPDIR/go-no-db"
  [ "$status" -ne 0 ]
}

@test "the go-no-db acceptance test passes on a reference solution" {
  command -v go >/dev/null 2>&1 || skip "go not installed"
  sh "$ROOT/tests/fixtures/generate.sh" "$BATS_TEST_TMPDIR" go-no-db >/dev/null
  # gofmt wants tabs; sed turns each \\t into one, so this file stays free of tabs
  printf '%s\n' \
    '// Command wordcount counts words (or lines with -l) read from stdin.' \
    'package main' \
    '' \
    'import (' \
    '\t"bufio"' \
    '\t"flag"' \
    '\t"fmt"' \
    '\t"os"' \
    ')' \
    '' \
    'func main() {' \
    '\tlines := flag.Bool("l", false, "count lines instead of words")' \
    '\tflag.Parse()' \
    '\ts := bufio.NewScanner(os.Stdin)' \
    '\tif !*lines {' \
    '\t\ts.Split(bufio.ScanWords)' \
    '\t}' \
    '\tn := 0' \
    '\tfor s.Scan() {' \
    '\t\tn++' \
    '\t}' \
    '\tfmt.Println(n)' \
    '}' \
    | sed "s/\\\\t/$TAB/g" > "$BATS_TEST_TMPDIR/go-no-db/main.go"
  run sh "$ROOT/tests/evals/effect/go-no-db.sh" "$BATS_TEST_TMPDIR/go-no-db"
  [ "$status" -eq 0 ]
}

@test "the difference uses the shown medians and never prints -0" {
  runs "$BATS_TEST_TMPDIR/e.tsv" \
    "without 1 10 100 1000 50 0.5000 7 60 pass" \
    "without 2 10 100 1000 50 0.5000 8 60 pass" \
    "with 1 10 100 1000 50 0.5000 12 60 pass" \
    "with 2 10 100 1000 50 0.5000 12 60 pass"
  run sh "$S" summary "$BATS_TEST_TMPDIR/e.tsv"
  [ "$status" -eq 0 ]
  [ "${lines[6]}" = "difference${TAB}median${TAB}+0${TAB}+0${TAB}+0${TAB}+0${TAB}+0.0000${TAB}+4${TAB}+0${TAB}+0" ]
}

@test "a report of the same day is not overwritten" {
  stub_claude
  mkdir -p "$BATS_TEST_TMPDIR/reports"
  : > "$BATS_TEST_TMPDIR/reports/effect-$(date +%Y-%m-%d).tsv"
  PATH="$STUB:$PATH" run sh "$S"
  [ "$status" -eq 2 ]
  assert_output_contains "not overwritten"
  [ ! -e "$BATS_TEST_TMPDIR/canned/calls" ]
}

@test "summary leaves a - in turns or duration out of the median" {
  runs "$BATS_TEST_TMPDIR/e.tsv" \
    "without 1 10 100 1000 50 0.5000 - 60 pass" \
    "without 2 10 100 1000 50 0.5000 4 - pass" \
    "without 3 10 100 1000 50 0.5000 6 80 pass"
  run sh "$S" summary "$BATS_TEST_TMPDIR/e.tsv"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "without${TAB}median${TAB}10${TAB}100${TAB}1000${TAB}50${TAB}0.5000${TAB}5${TAB}70${TAB}3/3" ]
  [ "${lines[1]}" = "without${TAB}min${TAB}10${TAB}100${TAB}1000${TAB}50${TAB}0.5000${TAB}4${TAB}60${TAB}-" ]
}

@test "summary skips the report's # header lines" {
  runs "$BATS_TEST_TMPDIR/e.tsv" "without 1 10 100 1000 50 0.5000 7 60 pass"
  { echo "# effect go-no-db, 3 runs per side"; cat "$BATS_TEST_TMPDIR/e.tsv"; } > "$BATS_TEST_TMPDIR/h.tsv"
  run sh "$S" summary "$BATS_TEST_TMPDIR/h.tsv"
  [ "${lines[0]}" = "without${TAB}median${TAB}10${TAB}100${TAB}1000${TAB}50${TAB}0.5000${TAB}7${TAB}60${TAB}1/1" ]
}

@test "comparison report: both sides, every run, medians, pass rate and the difference" {
  stub_claude
  result "$BATS_TEST_TMPDIR/canned/with-6.json" error_max_budget_usd 1.0 40 model-a
  PATH="$STUB:$PATH" GROMA_EFFECT_RUNS=3 run sh "$S"
  [ "$status" -eq 0 ]
  [ "$(cat "$BATS_TEST_TMPDIR/canned/calls")" -eq 6 ]
  assert_output_contains "max cost USD 6.00 (setup 0 + 2 x 3 x 1)"
  assert_output_contains "stopped by the budget cap"
  rep="$BATS_TEST_TMPDIR/reports/effect-$(date +%Y-%m-%d).tsv"
  [ -f "$rep" ]
  grep -q '^# setup: cost_usd -, model -' "$rep"
  grep -q "^# limit: both sides load the operator's user-level" "$rep"
  grep -q "^side${TAB}run${TAB}.*${TAB}pass${TAB}end${TAB}denials${TAB}model$" "$rep"
  # alternating order: without, with; with, without; without, with
  [ "$(grep -E '^with(out)?'"$TAB"'[0-9]' "$rep" | cut -f 1,2 | tr '\t\n' ': ')" = "without:1 with:1 with:2 without:2 without:3 with:3 " ]
  grep -q "^without${TAB}1${TAB}10${TAB}100${TAB}1000${TAB}50${TAB}0.1000${TAB}8${TAB}30${TAB}fail${TAB}success${TAB}0${TAB}model-a$" "$rep"
  grep -q "^with${TAB}3${TAB}.*${TAB}1.0000${TAB}40${TAB}30${TAB}fail${TAB}error_max_budget_usd${TAB}0${TAB}model-a$" "$rep"
  grep -q "^with${TAB}median${TAB}10${TAB}100${TAB}1000${TAB}50${TAB}0.5000${TAB}30${TAB}30${TAB}0/3$" "$rep"
  grep -q "^difference${TAB}median${TAB}+0${TAB}+0${TAB}+0${TAB}+0${TAB}+0.4000${TAB}+22${TAB}+0${TAB}+0$" "$rep"
  assert_output_contains "difference${TAB}median"
  [ ! -e "$BATS_TEST_TMPDIR/work/effect.tsv" ]
}

@test "a run stopped half-way leaves no report, so the same day can run again" {
  stub_claude
  # during the second call the set-up project vanishes, so the next copy fails
  printf 'rm -rf "%s"\n' "$GROMA_EFFECT_SETUP" > "$BATS_TEST_TMPDIR/canned/hook-2"
  PATH="$STUB:$PATH" run sh "$S"
  [ "$status" -ne 0 ]
  [ ! -e "$BATS_TEST_TMPDIR/reports/effect-$(date +%Y-%m-%d).tsv" ]
  rm -f "$BATS_TEST_TMPDIR/canned/hook-2" "$BATS_TEST_TMPDIR/canned/calls"
  stub_claude
  PATH="$STUB:$PATH" run sh "$S"
  [ "$status" -eq 0 ]
  [ -f "$BATS_TEST_TMPDIR/reports/effect-$(date +%Y-%m-%d).tsv" ]
}

@test "a missing fixture command stops before any API call" {
  stub_claude
  rm "$STUB/go" "$STUB/gofmt"
  PATH="$STUB:/usr/bin:/bin" command -v go >/dev/null 2>&1 && skip "go is in /usr/bin or /bin"
  PATH="$STUB:/usr/bin:/bin" run sh "$S"
  [ "$status" -eq 3 ]
  assert_output_contains "needs go"
  [ ! -e "$BATS_TEST_TMPDIR/canned/calls" ]
}

@test "a user-level groma skill outside the checkout stops before any API call with exit 3" {
  stub_claude
  mkdir -p "$BATS_TEST_TMPDIR/other/groma" "$HOME/.claude/skills"
  ln -s "$BATS_TEST_TMPDIR/other/groma" "$HOME/.claude/skills/groma"
  PATH="$STUB:$PATH" run sh "$S"
  [ "$status" -eq 3 ]
  assert_output_contains "skill-source:"
  [ ! -e "$BATS_TEST_TMPDIR/canned/calls" ]
  [ ! -e "$BATS_TEST_TMPDIR/work" ]
}

@test "GROMA_EFFECT_SETUP must be a folder" {
  GROMA_EFFECT_SETUP="$BATS_TEST_TMPDIR/none" run sh "$S"
  [ "$status" -eq 2 ]
  assert_output_contains "not a folder"
}
