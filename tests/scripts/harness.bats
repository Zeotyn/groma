#!/usr/bin/env bats
# Sanity checks for the test harness itself.

load helpers

@test "make_repo creates a git repo with deterministic identity" {
  make_repo "$BATS_TEST_TMPDIR/r"
  run git -C "$BATS_TEST_TMPDIR/r" config user.email
  [ "$status" -eq 0 ]
  [ "$output" = "test@groma.invalid" ]
}

@test "commit_at sets a fixed commit date" {
  make_repo "$BATS_TEST_TMPDIR/r"
  echo x > "$BATS_TEST_TMPDIR/r/a.txt"
  commit_at "$BATS_TEST_TMPDIR/r" 2024-01-15 "first"
  run git -C "$BATS_TEST_TMPDIR/r" log -1 --format=%cs
  [ "$output" = "2024-01-15" ]
}
