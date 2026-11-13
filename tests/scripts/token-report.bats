#!/usr/bin/env bats
# token-report.sh turns `claude -p --output-format json` results into the eval
# token report. The samples in tests/evals/samples/ are synthetic results in the
# shape Claude Code prints; no test here calls a model.

load helpers

S="$ROOT/tests/evals/token-report.sh"
SAMPLES="$ROOT/tests/evals/samples"
TAB=$(printf '\t')

# report with a header and the given rows (one argument per row, fields separated by spaces)
report() { # file rows...
  f=$1; shift
  sh "$S" header > "$f"
  for r in "$@"; do printf '%s\n' "$r" | tr ' ' '\t' >> "$f"; done
}

@test "header names the columns" {
  run sh "$S" header
  [ "$status" -eq 0 ]
  [ "$output" = "fixture${TAB}input_tokens${TAB}output_tokens${TAB}cache_read_tokens${TAB}cache_write_tokens${TAB}cost_usd${TAB}turns${TAB}duration_s" ]
}

@test "row sums the tokens of every model and rounds cost and duration" {
  run sh "$S" row empty "$SAMPLES/result-success.json"
  [ "$status" -eq 0 ]
  [ "$output" = "empty${TAB}3120${TAB}15200${TAB}900000${TAB}45000${TAB}1.2346${TAB}42${TAB}183" ]
}

@test "row ignores token fields quoted inside the result text" {
  run sh "$S" row empty "$SAMPLES/result-success.json"
  case "$output" in *999999*|*99.0000*) false ;; esac
}

@test "row falls back to usage without modelUsage and reads pretty-printed JSON" {
  run sh "$S" row node-prisma "$SAMPLES/result-budget.json"
  [ "$status" -eq 0 ]
  [ "$output" = "node-prisma${TAB}50${TAB}8000${TAB}400000${TAB}20000${TAB}3.0012${TAB}17${TAB}62" ]
}

@test "row prints dashes when the result is missing, empty or not JSON" {
  run sh "$S" row go-no-db "$BATS_TEST_TMPDIR/none.json"
  [ "$status" -eq 0 ]
  [ "$output" = "go-no-db${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-" ]
  printf 'Error: not logged in\n' > "$BATS_TEST_TMPDIR/bad.json"
  run sh "$S" row go-no-db "$BATS_TEST_TMPDIR/bad.json"
  [ "$output" = "go-no-db${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-" ]
}

@test "text prints the result text unescaped" {
  run sh "$S" text "$SAMPLES/result-success.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'Done: groma set up docs/ and "AGENTS.md".' ]
  [ "${lines[1]}" = "${TAB}Not counted: {\"usage\":{\"input_tokens\":999999},\"total_cost_usd\":99}" ]
  [ "${lines[2]}" = "Next: npx groma-cli update" ]
}

@test "row prints dashes for a result without token counts or cost" {
  printf '{"type":"result","is_error":true,"total_cost_usd":0.5,"num_turns":3,"duration_ms":1000}\n' > "$BATS_TEST_TMPDIR/r.json"
  run sh "$S" row empty "$BATS_TEST_TMPDIR/r.json"
  [ "$output" = "empty${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-" ]
  printf '{"usage":{"input_tokens":5,"output_tokens":1}}\n' > "$BATS_TEST_TMPDIR/r.json"
  run sh "$S" row empty "$BATS_TEST_TMPDIR/r.json"
  [ "$output" = "empty${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-${TAB}-" ]
}

@test "row prints a dash for missing turns or duration only" {
  printf '{"total_cost_usd":0.5,"usage":{"input_tokens":5,"output_tokens":1}}\n' > "$BATS_TEST_TMPDIR/r.json"
  run sh "$S" row empty "$BATS_TEST_TMPDIR/r.json"
  [ "$output" = "empty${TAB}5${TAB}1${TAB}0${TAB}0${TAB}0.5000${TAB}-${TAB}-" ]
}

@test "text names subtype and is_error when the result has no text" {
  run sh "$S" text "$SAMPLES/result-budget.json"
  [ "$status" -eq 0 ]
  [ "$output" = "no result text: subtype=error_max_budget_usd is_error=true" ]
}

@test "text prints nothing for a missing file" {
  run sh "$S" text "$BATS_TEST_TMPDIR/none.json"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "summary prints one line per fixture and ends with the totals" {
  report "$BATS_TEST_TMPDIR/r.tsv" "empty 100 10 1000 50 1.5000 10 60" "go-no-db 200 20 2000 150 0.5000 5 40"
  run sh "$S" summary "$BATS_TEST_TMPDIR/r.tsv"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = "fixture${TAB}empty${TAB}input=100${TAB}output=10${TAB}cache_read=1000${TAB}cache_write=50${TAB}cost_usd=1.5000${TAB}turns=10${TAB}duration_s=60" ]
  [ "${lines[2]}" = "summary${TAB}fixtures=2${TAB}input=300${TAB}output=30${TAB}cache_read=3000${TAB}cache_write=200${TAB}cost_usd=2.0000${TAB}turns=15${TAB}duration_s=100" ]
}

@test "summary shows each fixture's difference against the baseline" {
  report "$BATS_TEST_TMPDIR/b.tsv" "empty 120 10 900 50 1.7000 12 70" "go-no-db 200 25 2000 100 0.4000 5 40" "loop-openspec 1 1 1 1 9.0000 1 1"
  report "$BATS_TEST_TMPDIR/r.tsv" "empty 100 10 1000 50 1.5000 10 60" "go-no-db 200 20 2000 150 0.5000 5 40" "cli-node-prisma 7 7 7 7 0.7000 7 7"
  run sh "$S" summary "$BATS_TEST_TMPDIR/r.tsv" "$BATS_TEST_TMPDIR/b.tsv"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "fixture${TAB}empty${TAB}input=100${TAB}output=10${TAB}cache_read=1000${TAB}cache_write=50${TAB}cost_usd=1.5000${TAB}turns=10${TAB}duration_s=60${TAB}vs_baseline${TAB}input=-20${TAB}output=+0${TAB}cache_read=+100${TAB}cache_write=+0${TAB}cost_usd=-0.2000" ]
  [ "${lines[1]}" = "fixture${TAB}go-no-db${TAB}input=200${TAB}output=20${TAB}cache_read=2000${TAB}cache_write=150${TAB}cost_usd=0.5000${TAB}turns=5${TAB}duration_s=40${TAB}vs_baseline${TAB}input=+0${TAB}output=-5${TAB}cache_read=+0${TAB}cache_write=+50${TAB}cost_usd=+0.1000" ]
  assert_output_contains "fixture${TAB}cli-node-prisma${TAB}input=7"
  assert_output_contains "duration_s=7${TAB}vs_baseline${TAB}new"
  # totals compare only fixtures present in both files
  [ "${lines[3]}" = "summary${TAB}fixtures=3${TAB}input=307${TAB}output=37${TAB}cache_read=3007${TAB}cache_write=207${TAB}cost_usd=2.7000${TAB}turns=22${TAB}duration_s=107${TAB}vs_baseline${TAB}input=-20${TAB}output=-5${TAB}cache_read=+100${TAB}cache_write=+50${TAB}cost_usd=-0.1000" ]
}

@test "summary counts a fixture without a result but leaves it out of the totals" {
  report "$BATS_TEST_TMPDIR/b.tsv" "empty 120 10 900 50 1.7000 12 70"
  report "$BATS_TEST_TMPDIR/r.tsv" "empty - - - - - - -" "go-no-db 200 20 2000 150 0.5000 5 40"
  run sh "$S" summary "$BATS_TEST_TMPDIR/r.tsv" "$BATS_TEST_TMPDIR/b.tsv"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "fixture${TAB}empty${TAB}no result${TAB}vs_baseline${TAB}-" ]
  [ "${lines[2]}" = "summary${TAB}fixtures=2${TAB}no_result=1${TAB}input=200${TAB}output=20${TAB}cache_read=2000${TAB}cache_write=150${TAB}cost_usd=0.5000${TAB}turns=5${TAB}duration_s=40${TAB}vs_baseline${TAB}-" ]
}

@test "summary says no baseline when the baseline row has no result" {
  report "$BATS_TEST_TMPDIR/b.tsv" "empty - - - - - - -"
  report "$BATS_TEST_TMPDIR/r.tsv" "empty 100 10 1000 50 1.5000 10 60"
  run sh "$S" summary "$BATS_TEST_TMPDIR/r.tsv" "$BATS_TEST_TMPDIR/b.tsv"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "fixture${TAB}empty${TAB}input=100${TAB}output=10${TAB}cache_read=1000${TAB}cache_write=50${TAB}cost_usd=1.5000${TAB}turns=10${TAB}duration_s=60${TAB}vs_baseline${TAB}no baseline" ]
  # no fixture in common: no difference in the totals
  [ "${lines[1]}" = "summary${TAB}fixtures=1${TAB}input=100${TAB}output=10${TAB}cache_read=1000${TAB}cache_write=50${TAB}cost_usd=1.5000${TAB}turns=10${TAB}duration_s=60${TAB}vs_baseline${TAB}-" ]
}

@test "summary shows a dash for missing turns and counts it as 0" {
  report "$BATS_TEST_TMPDIR/r.tsv" "empty 100 10 1000 50 1.5000 - -" "go-no-db 200 20 2000 150 0.5000 5 40"
  run sh "$S" summary "$BATS_TEST_TMPDIR/r.tsv"
  [ "${lines[0]}" = "fixture${TAB}empty${TAB}input=100${TAB}output=10${TAB}cache_read=1000${TAB}cache_write=50${TAB}cost_usd=1.5000${TAB}turns=-${TAB}duration_s=-" ]
  [ "${lines[2]}" = "summary${TAB}fixtures=2${TAB}input=300${TAB}output=30${TAB}cache_read=3000${TAB}cache_write=200${TAB}cost_usd=2.0000${TAB}turns=5${TAB}duration_s=40" ]
}

@test "usage errors exit 2" {
  run sh "$S"
  [ "$status" -eq 2 ]
  run sh "$S" row empty
  [ "$status" -eq 2 ]
  run sh "$S" summary "$BATS_TEST_TMPDIR/none.tsv"
  [ "$status" -eq 2 ]
  run sh "$S" bogus
  [ "$status" -eq 2 ]
}

@test "run.sh writes the dated report and ends with the totals (stub claude, no model call)" {
  mkdir -p "$BATS_TEST_TMPDIR/bin" "$BATS_TEST_TMPDIR/reports"
  printf '#!/bin/sh\ncat "%s"\n' "$SAMPLES/result-success.json" > "$BATS_TEST_TMPDIR/bin/claude"
  chmod +x "$BATS_TEST_TMPDIR/bin/claude"
  report "$BATS_TEST_TMPDIR/reports/baseline.tsv" "empty 3000 15000 900000 45000 1.0000 40 180"
  PATH="$BATS_TEST_TMPDIR/bin:$PATH" GROMA_EVAL_DIR="$BATS_TEST_TMPDIR/work" \
    GROMA_EVAL_REPORTS="$BATS_TEST_TMPDIR/reports" run sh "$ROOT/tests/evals/run.sh" empty
  # the stub writes no files, so the assertions fail; the report is still written
  [ "$status" -eq 1 ]
  f=$(ls "$BATS_TEST_TMPDIR/reports"/[0-9]*.tsv)
  case "$f" in */[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9].tsv) ;; *) false ;; esac
  assert_output_contains "report: $f"
  [ "$(sed -n 2p "$f")" = "empty${TAB}3120${TAB}15200${TAB}900000${TAB}45000${TAB}1.2346${TAB}42${TAB}183" ]
  assert_output_contains "vs_baseline${TAB}input=+120"
  case "${lines[${#lines[@]}-1]}" in "summary${TAB}fixtures=1${TAB}"*) ;; *) false ;; esac
  grep -q "Next: npx groma-cli update" "$BATS_TEST_TMPDIR/work/empty.log"
  # a second run writes its own report instead of overwriting the first
  sleep 1
  PATH="$BATS_TEST_TMPDIR/bin:$PATH" GROMA_EVAL_DIR="$BATS_TEST_TMPDIR/work" \
    GROMA_EVAL_REPORTS="$BATS_TEST_TMPDIR/reports" run sh "$ROOT/tests/evals/run.sh" empty
  [ "$(ls "$BATS_TEST_TMPDIR/reports"/[0-9]*.tsv | wc -l | tr -d ' ')" -eq 2 ]
}
