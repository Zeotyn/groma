#!/usr/bin/env bats
# report-check.sh checks a survey findings report: the template's
# generated_by line, every section of the findings template present and not
# empty, no placeholder left, and a Hand-off section of one to ten lines (what
# a survey subagent hands back to the main session).

load helpers

S="$ROOT/skills/groma-survey/scripts/report-check.sh"
T="$ROOT/skills/groma-survey/templates/findings.md"
TAB=$(printf '\t')

# a filled report: every heading of the template, then the given hand-off lines
report() { # file handoff-lines...
  f=$1; shift
  {
    printf -- '---\ntitle: groma survey findings 2026-11-16\ngenerated_by: groma-survey\n---\n\n# Survey findings, 2026-11-16\n'
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

@test "template-shaped placeholders count, other braces in evidence do not" {
  report "$BATS_TEST_TMPDIR/r.md" "- one finding"
  {
    printf '| 2 | low | helm | `{{ .Values.image }}` in chart | `chart/values.yaml` | none |\n'
    printf 'Jinja evidence {{ user.name }} and Vue {{ message }} in prose\n'
    printf '```\n{{severity}} inside a fenced block\n```\n'
    printf 'an unknown name {{tenant}} is project text\n'
  } >> "$BATS_TEST_TMPDIR/r.md"
  run sh "$S" "$BATS_TEST_TMPDIR/r.md"
  [ "$status" -eq 0 ]
  printf '| Prettier | x | `{{check_command}}` | `{{fix_command}}` |\n' >> "$BATS_TEST_TMPDIR/r.md"
  printf 'Data model: {{data_model: entities}}\n' >> "$BATS_TEST_TMPDIR/r.md"
  run sh "$S" "$BATS_TEST_TMPDIR/r.md"
  [ "$status" -eq 1 ]
  n=$(wc -l < "$BATS_TEST_TMPDIR/r.md" | tr -d ' ')
  assert_output_contains "placeholder${TAB}$((n - 1))"
  assert_output_contains "placeholder${TAB}${n}"
}

@test "a heading matches the template by its text before a parenthesis" {
  report "$BATS_TEST_TMPDIR/r.md" "- one finding"
  sed 's/^## Proposed ADRs (status: proposed)$/## Proposed ADRs/' "$BATS_TEST_TMPDIR/r.md" > "$BATS_TEST_TMPDIR/s.md"
  run sh "$S" "$BATS_TEST_TMPDIR/s.md"
  [ "$status" -eq 0 ]
}

@test "only the first Hand-off section counts" {
  report "$BATS_TEST_TMPDIR/r.md" "- one finding"
  printf '\n## Hand-off\n\n1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n' >> "$BATS_TEST_TMPDIR/r.md"
  run sh "$S" "$BATS_TEST_TMPDIR/r.md"
  [ "$status" -eq 0 ]
  assert_output_contains "handoff${TAB}1"
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

@test "a report without the template's generated_by line is incomplete" {
  report "$BATS_TEST_TMPDIR/r.md" "- one finding"
  grep -v '^generated_by:' "$BATS_TEST_TMPDIR/r.md" > "$BATS_TEST_TMPDIR/s.md"
  run sh "$S" "$BATS_TEST_TMPDIR/s.md"
  [ "$status" -eq 1 ]
  assert_output_contains "missing${TAB}generated_by: groma-survey"
  # a generated_by line in the body is not frontmatter
  printf 'generated_by: groma-survey\n' >> "$BATS_TEST_TMPDIR/s.md"
  run sh "$S" "$BATS_TEST_TMPDIR/s.md"
  [ "$status" -eq 1 ]
}

@test "a condensed report of its own format names every missing part" {
  printf '# groma findings, 2026-11-16\n\n## Hand-off\n\n- 1 high\n\n## Findings\n\n| # | Severity |\n|---|---|\n| 1 | high |\n' > "$BATS_TEST_TMPDIR/s.md"
  run sh "$S" "$BATS_TEST_TMPDIR/s.md"
  [ "$status" -eq 1 ]
  assert_output_contains "missing${TAB}generated_by: groma-survey"
  assert_output_contains "missing${TAB}## Survey scope"
  assert_output_contains "missing${TAB}## Data model draft"
  case "$output" in *"missing${TAB}## Findings"*) false ;; esac
}

@test "a section with a table header and no rows is empty, None found. fills it" {
  report "$BATS_TEST_TMPDIR/r.md" "- one finding"
  awk '/^## ADRs found$/ { print; print ""; print "| ADR | Title | Status | Path |"; print "|---|---|---|---|"; skip = 1; next }
    /^## / { skip = 0 } !skip' "$BATS_TEST_TMPDIR/r.md" > "$BATS_TEST_TMPDIR/s.md"
  run sh "$S" "$BATS_TEST_TMPDIR/s.md"
  [ "$status" -eq 1 ]
  assert_output_contains "empty${TAB}## ADRs found"
  awk '{ print } /^\|---\|---\|---\|---\|$/ { print ""; print "None found." }' \
    "$BATS_TEST_TMPDIR/s.md" > "$BATS_TEST_TMPDIR/t.md"
  run sh "$S" "$BATS_TEST_TMPDIR/t.md"
  [ "$status" -eq 0 ]
  awk '{ print } /^\|---\|---\|---\|---\|$/ { print "| 0001 | Use Postgres | accepted | `doc/adr/0001.md` |" }' \
    "$BATS_TEST_TMPDIR/s.md" > "$BATS_TEST_TMPDIR/t.md"
  run sh "$S" "$BATS_TEST_TMPDIR/t.md"
  [ "$status" -eq 0 ]
}

@test "a section with only a fenced block has content" {
  report "$BATS_TEST_TMPDIR/r.md" "- one finding"
  awk '/^## Snippets for existing files$/ { print; print ""; print "```json"; print "{}"; print "```"; skip = 1; next }
    /^## / { skip = 0 } !skip' "$BATS_TEST_TMPDIR/r.md" > "$BATS_TEST_TMPDIR/s.md"
  run sh "$S" "$BATS_TEST_TMPDIR/s.md"
  [ "$status" -eq 0 ]
}

@test "missing report and usage errors" {
  run sh "$S" "$BATS_TEST_TMPDIR/nope.md"
  [ "$status" -eq 2 ]
  run sh "$S"
  [ "$status" -eq 2 ]
}
