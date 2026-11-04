#!/usr/bin/env bats

load helpers

DETECT="$ROOT/skills/groma-detect/scripts/detect.sh"

setup_file() {
  sh "$ROOT/tests/fixtures/generate.sh" "$BATS_FILE_TMPDIR/f" >/dev/null
}

F() { echo "$BATS_FILE_TMPDIR/f/$1"; }

@test "empty folder is greenfield" {
  run sh "$DETECT" "$(F empty)"
  [ "$status" -eq 0 ]
  assert_output_contains "project_type=greenfield"
  assert_output_contains "signal=no source files"
}

@test "node-prisma is brownfield with JavaScript and package.json" {
  run sh "$DETECT" "$(F node-prisma)"
  assert_output_contains "project_type=brownfield"
  assert_output_contains "signal=source files: .js (JavaScript) x1"
  assert_output_contains "signal=manifest: package.json (Node.js)"
}

@test "java-flyway counts java and sql" {
  run sh "$DETECT" "$(F java-flyway)"
  assert_output_contains "project_type=brownfield"
  assert_output_contains ".java (Java) x2"
  assert_output_contains ".sql (SQL) x2"
  assert_output_contains "manifest: pom.xml"
}

@test "go-no-db is brownfield" {
  run sh "$DETECT" "$(F go-no-db)"
  assert_output_contains "project_type=brownfield"
  assert_output_contains "manifest: go.mod (Go)"
}

@test "docs only is greenfield with docs present" {
  D="$BATS_TEST_TMPDIR/docs-only"
  mkdir -p "$D/docs" && echo "# idea" > "$D/docs/idea.md"
  run sh "$DETECT" "$D"
  assert_output_contains "project_type=greenfield"
  assert_output_contains "signal=docs present"
}

@test "unknown language counts as brownfield, unrecognized stack" {
  D="$BATS_TEST_TMPDIR/gleam"
  mkdir -p "$D/src" && echo "pub fn main() {}" > "$D/src/app.gleamx"
  run sh "$DETECT" "$D"
  assert_output_contains "project_type=brownfield"
  assert_output_contains "signal=source files: .gleamx (unrecognized stack) x1"
}

@test "agent and methodology folders do not make a project brownfield" {
  D="$BATS_TEST_TMPDIR/agentonly"
  mkdir -p "$D/.claude/skills/x" "$D/openspec" "$D/node_modules/a"
  echo "x" > "$D/.claude/skills/x/run.py"
  echo "x" > "$D/node_modules/a/index.js"
  echo "schema: spec-driven" > "$D/openspec/config.yaml"
  run sh "$DETECT" "$D"
  assert_output_contains "project_type=greenfield"
}

@test "more than 10 commits makes a project brownfield" {
  D="$BATS_TEST_TMPDIR/hist"
  make_repo "$D"
  for i in 1 2 3 4 5 6 7 8 9 10 11; do
    echo "$i" > "$D/notes.md"
    commit_at "$D" 2025-01-$(printf %02d "$i") "n$i"
  done
  run sh "$DETECT" "$D"
  assert_output_contains "project_type=brownfield"
  assert_output_contains "signal=git history: 11 commits"
}

@test "fails on missing directory" {
  run sh "$DETECT" "$BATS_TEST_TMPDIR/nope"
  [ "$status" -eq 2 ]
}
