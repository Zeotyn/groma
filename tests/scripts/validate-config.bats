#!/usr/bin/env bats

load helpers

V="$ROOT/skills/groma/scripts/validate-config.sh"
TPL="$ROOT/skills/groma/templates/config.yaml"

setup() {
  CAT="$BATS_TEST_TMPDIR/catalog.yaml"
  cat > "$CAT" <<'EOF'
schema: 1
categories:
  design:
    description: d
    select: single
    condition: has_ui
    recommended: impeccable
    options: [impeccable, frontend-design, none]
  writing:
    description: w
    select: multi
    recommended: [anti-ai-slop-writing]
    options:
      - anti-ai-slop-writing
      - i-have-adhd
      - none
  workflow:
    description: wf
    select: single
    recommended: superpowers
    options: [superpowers, none]
skills:
  impeccable: {title: x}
  frontend-design: {title: x}
  anti-ai-slop-writing: {title: x}
  i-have-adhd: {title: x}
  superpowers: {title: x}
EOF
  C="$BATS_TEST_TMPDIR/config.yaml"
  cat > "$C" <<'EOF'
schema: 1
initialized_with: groma@0.1.0
project:
  name: shop
  has_ui: true
project_type: brownfield
project_type_override: none
methodology: openspec   # comment
workflow: superpowers
agents: [claude, copilot]
skills:
  design: impeccable
  writing: [anti-ai-slop-writing, i-have-adhd]
docs:
  review_after_days: 90
  optional: [security]
conventions:
  changes:
    enabled: true
    digits: 3
    types:
      m: milestone
steps:
  detect: done
  interview: pending
EOF
}

@test "valid config passes with catalog" {
  run sh "$V" "$C" --catalog "$CAT"
  [ "$status" -eq 0 ]
  assert_output_contains "summary	errors=0	warnings=0"
}

@test "typo in skill id reports line and closest match" {
  sed -i.bak 's/design: impeccable/design: impecable/' "$C"
  run sh "$V" "$C" --catalog "$CAT"
  [ "$status" -eq 1 ]
  assert_output_contains "error	line 12	unknown skill id 'impecable' in category 'design', closest catalog match: impeccable"
}

@test "single-select category with two skills fails" {
  sed -i.bak 's/design: impeccable/design: [impeccable, frontend-design]/' "$C"
  run sh "$V" "$C" --catalog "$CAT"
  assert_output_contains "single-select but lists 2 skills"
}

@test "unknown category fails" {
  printf '  colors: rainbow\n' > "$BATS_TEST_TMPDIR/extra"
  sed -i.bak '/writing:/r '"$BATS_TEST_TMPDIR/extra" "$C"
  run sh "$V" "$C" --catalog "$CAT"
  assert_output_contains "unknown catalog category 'colors'"
}

@test "unknown agent suggests closest" {
  sed -i.bak 's/agents: \[claude, copilot\]/agents: [claude, copilto]/' "$C"
  run sh "$V" "$C"
  assert_output_contains "unknown agent 'copilto'"
  assert_output_contains "did you mean copilot?"
}

@test "unknown methodology fails" {
  sed -i.bak 's/methodology: openspec/methodology: open-spec/' "$C"
  run sh "$V" "$C"
  [ "$status" -eq 1 ]
  assert_output_contains "did you mean openspec?"
}

@test "missing required key fails" {
  sed -i.bak '/^methodology:/d' "$C"
  run sh "$V" "$C"
  assert_output_contains "missing required key 'methodology'"
}

@test "newer schema stops with update hint and exit 3" {
  sed -i.bak 's/^schema: 1/schema: 3/' "$C"
  run sh "$V" "$C"
  [ "$status" -eq 3 ]
  assert_output_contains "config uses schema 3, this groma supports up to 1"
}

@test "invalid step value fails" {
  sed -i.bak 's/interview: pending/interview: maybe/' "$C"
  run sh "$V" "$C"
  assert_output_contains "steps.interview must be done, pending or skipped"
}

@test "unknown top-level key is a warning only" {
  echo "colour: blue" >> "$C"
  run sh "$V" "$C"
  [ "$status" -eq 0 ]
  assert_output_contains "warning	line"
  assert_output_contains "unknown top-level key 'colour'"
}

@test "filled template validates against the real catalog" {
  [ -f "$ROOT/skills/groma-skills/catalog.yaml" ] || skip "catalog not written yet"
  sed -e 's/{{version}}/0.1.0/' -e 's/{{project_name}}/x/' -e 's/{{has_ui}}/false/' \
      -e 's/{{project_type}}/greenfield/' -e 's/{{methodology}}/openspec/' -e 's/{{workflow}}/none/' \
      -e 's/{{agents}}/claude, copilot/' -e 's/{{skills_design}}/none/' \
      -e 's/{{skills_writing}}/anti-ai-slop-writing, i-have-adhd/' -e 's/{{skills_pragmatism}}/ponytail/' \
      -e 's/{{skills_diagrams}}/archify/' -e 's/{{skills_discovery}}/graphify/' "$TPL" > "$C"
  run sh "$V" "$C" --catalog "$ROOT/skills/groma-skills/catalog.yaml"
  echo "$output"
  [ "$status" -eq 0 ]
}
