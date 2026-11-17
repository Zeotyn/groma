#!/usr/bin/env bats
# effect.sh compares one task with and without groma's setup (c013). Only the
# parts that never call a model are tested here: the summary and the checks
# before the first API call.

load helpers

S="$ROOT/tests/evals/effect.sh"
TAB=$(printf '\t')

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
  cat > "$BATS_TEST_TMPDIR/go-no-db/main.go" <<'GO'
// Command wordcount counts words (or lines with -l) read from stdin.
package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
)

func main() {
	lines := flag.Bool("l", false, "count lines instead of words")
	flag.Parse()
	s := bufio.NewScanner(os.Stdin)
	if !*lines {
		s.Split(bufio.ScanWords)
	}
	n := 0
	for s.Scan() {
		n++
	}
	fmt.Println(n)
}
GO
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
  stub="$BATS_TEST_TMPDIR/bin"; mkdir -p "$stub"
  printf '#!/bin/sh\nexit 0\n' > "$stub/claude"; chmod +x "$stub/claude"
  mkdir -p "$BATS_TEST_TMPDIR/reports"
  : > "$BATS_TEST_TMPDIR/reports/effect-$(date +%Y-%m-%d).tsv"
  PATH="$stub:$PATH" GROMA_EVAL_REPORTS="$BATS_TEST_TMPDIR/reports" run sh "$S"
  [ "$status" -eq 2 ]
  assert_output_contains "not overwritten"
}
