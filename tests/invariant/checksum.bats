#!/usr/bin/env bats

load ../scripts/helpers

CHECK="$ROOT/tests/invariant/checksum.sh"

setup() {
  D="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$D/docs" "$D/my dir"
  echo "hello" > "$D/README.md"
  echo "arch" > "$D/docs/architecture.md"
  echo "spaced" > "$D/my dir/file with spaces.txt"
  M="$BATS_TEST_TMPDIR/manifest"
  sh "$CHECK" snapshot "$D" "$M"
}

@test "passes when nothing changed" {
  run sh "$CHECK" verify "$D" "$M"
  [ "$status" -eq 0 ]
  assert_output_contains "invariant ok"
}

@test "passes when only files were added" {
  echo "new" > "$D/docs/vision.md"
  mkdir -p "$D/.groma" && echo "x" > "$D/.groma/config.yaml"
  run sh "$CHECK" verify "$D" "$M"
  [ "$status" -eq 0 ]
}

@test "fails and names a changed file" {
  echo "rewritten" > "$D/README.md"
  run sh "$CHECK" verify "$D" "$M"
  [ "$status" -eq 1 ]
  assert_output_contains "CHANGED  ./README.md"
}

@test "fails and names a removed file" {
  rm "$D/docs/architecture.md"
  run sh "$CHECK" verify "$D" "$M"
  [ "$status" -eq 1 ]
  assert_output_contains "MISSING  ./docs/architecture.md"
}

@test "handles file names with spaces" {
  echo "changed" > "$D/my dir/file with spaces.txt"
  run sh "$CHECK" verify "$D" "$M"
  [ "$status" -eq 1 ]
  assert_output_contains "CHANGED  ./my dir/file with spaces.txt"
}

@test "ignores the .git directory" {
  make_repo "$D"
  run sh "$CHECK" verify "$D" "$M"
  [ "$status" -eq 0 ]
}
