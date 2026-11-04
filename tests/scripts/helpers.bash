# Shared helpers for bats tests.
# shellcheck shell=bash

ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
export ROOT
SCRIPTS="$ROOT/scripts"
export SCRIPTS

# Create a throwaway git repo with deterministic identity and dates.
# Usage: make_repo <dir>
make_repo() {
  mkdir -p "$1"
  git -C "$1" init -q -b main
  git -C "$1" config user.name "groma-test"
  git -C "$1" config user.email "test@groma.invalid"
  git -C "$1" config commit.gpgsign false
}

# Commit everything in <dir> at a fixed ISO date.
# Usage: commit_at <dir> <YYYY-MM-DD> <message>
commit_at() {
  git -C "$1" add -A
  GIT_AUTHOR_DATE="$2T12:00:00Z" GIT_COMMITTER_DATE="$2T12:00:00Z" \
    git -C "$1" commit -q -m "$3"
}

assert_output_contains() {
  case "$output" in
    *"$1"*) return 0 ;;
    *) echo "expected output to contain: $1"; echo "actual: $output"; return 1 ;;
  esac
}

assert_output_not_contains() {
  case "$output" in
    *"$1"*) echo "expected output NOT to contain: $1"; echo "actual: $output"; return 1 ;;
    *) return 0 ;;
  esac
}
