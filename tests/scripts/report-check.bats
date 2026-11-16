#!/usr/bin/env bats
# report-check.sh checks a survey findings report: every section of the
# findings template present, no placeholder left, and a Hand-off section of one
# to ten lines (what a survey subagent hands back to the main session).

load helpers

S="$ROOT/skills/groma-survey/scripts/report-check.sh"
T="$ROOT/skills/groma-survey/templates/findings.md"
TAB=$(printf '\t')

# a filled report: every heading of the template, then the given hand-off lines
report() { # file handoff-lines...
  f=$1; shift
  {
    printf -- '---\ntitle: groma survey findings 2026-11-16\n---\n\n# Survey findings, 2026-11-16\n'
    grep '^## ' "$T" | grep -v '^## Hand-off' | while IFS= read -r h; do printf '\n%s\n\nfilled\n' "$h"; done
    printf '\n## Hand-off\n\n'
    for l in "$@"; do printf '%s\n' "$l"; done
  } > "$f"
}

@test "the template has the sections the survey hands back" {
  grep -q '^## Survey scope$' "$T"
  grep -q '^## Hand-off$' "$T"
}

@test "complete report with a short hand-off passes" {
  report "$BATS_TEST_TMPDIR/r.md" "- 3 high, 2 medium" "- data model: User, Order" "- next: groma-lay-out"
  run sh "$S" "$BATS_TEST_TMPDIR/r.md"
  [ "$status" -eq 0 ]
  assert_output_contains "handoff${TAB}3"
  [ "${lines[${#lines[@]}-1]}" = "summary${TAB}ok" ]
}

@test "ten hand-off lines pass, eleven fail" {
  report "$BATS_TEST_TMPDIR/r.md" 1 2 3 4 5 6 7 8 9 10
  run sh "$S" "$BATS_TEST_TMPDIR/r.md"
  [ "$status" -eq 0 ]
  report "$BATS_TEST_TMPDIR/r.md" 1 2 3 4 5 6 7 8 9 10 11
  run sh "$S" "$BATS_TEST_TMPDIR/r.md"
  [ "$status" -eq 1 ]
  assert_output_contains "handoff${TAB}11"
  assert_output_contains "summary${TAB}incomplete"
}

@test "an empty hand-off fails" {
  report "$BATS_TEST_TMPDIR/r.md"
  run sh "$S" "$BATS_TEST_TMPDIR/r.md"
  [ "$status" -eq 1 ]
  assert_output_contains "handoff${TAB}0"
}

@test "a missing section is named" {
  report "$BATS_TEST_TMPDIR/r.md" "- one finding"
  grep -v '^## Data model draft$' "$BATS_TEST_TMPDIR/r.md" > "$BATS_TEST_TMPDIR/s.md"
  run sh "$S" "$BATS_TEST_TMPDIR/s.md"
  [ "$status" -eq 1 ]
  assert_output_contains "missing${TAB}## Data model draft"
}

@test "a placeholder left in the report is named with its line" {
  report "$BATS_TEST_TMPDIR/r.md" "- one finding"
  printf '| 1 | {{severity}} |\n' >> "$BATS_TEST_TMPDIR/r.md"
  run sh "$S" "$BATS_TEST_TMPDIR/r.md"
  [ "$status" -eq 1 ]
  n=$(wc -l < "$BATS_TEST_TMPDIR/r.md" | tr -d ' ')
  assert_output_contains "placeholder${TAB}${n}"
}

@test "the hand-off ends at the next section" {
  report "$BATS_TEST_TMPDIR/r.md" "- one finding"
  printf '\n## Read first\n\na\nb\nc\nd\ne\nf\ng\nh\ni\nj\n' >> "$BATS_TEST_TMPDIR/r.md"
  run sh "$S" "$BATS_TEST_TMPDIR/r.md"
  [ "$status" -eq 0 ]
  assert_output_contains "handoff${TAB}1"
}

@test "report from before the hand-off fails on the new sections only" {
  report "$BATS_TEST_TMPDIR/r.md" "- one finding"
  awk '/^## (Survey scope|Hand-off)$/ { skip = 1; next } /^## / { skip = 0 } !skip' \
    "$BATS_TEST_TMPDIR/r.md" > "$BATS_TEST_TMPDIR/old.md"
  run sh "$S" "$BATS_TEST_TMPDIR/old.md"
  [ "$status" -eq 1 ]
  assert_output_contains "missing${TAB}## Survey scope"
  assert_output_contains "missing${TAB}## Hand-off"
  assert_output_contains "handoff${TAB}0"
  case "$output" in *"missing${TAB}## Findings"*) false ;; esac
}

@test "missing report and usage errors" {
  run sh "$S" "$BATS_TEST_TMPDIR/nope.md"
  [ "$status" -eq 2 ]
  run sh "$S"
  [ "$status" -eq 2 ]
}
