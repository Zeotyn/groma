#!/bin/sh
# Build git repositories whose histories git-practice.sh (groma-detect) classifies.
#
# Histories (deterministic identity, dates and subjects):
#   pr-merge             main holds 8 merges: 6 "Merge pull request", 1 "Merge branch",
#                        1 custom; the 10 non-merge commits are 8 conventional, 2 free
#   squash               10 commits on main, no merges, 8 end in (#n), 8 conventional
#   linear-conventional  10 commits on main, no merges, 9 conventional
#
# Usage: tests/fixtures/histories.sh [target-dir] [history...]
#   target-dir defaults to tests/.work/histories; prints one target path per history
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TARGET=${1:-"$HERE/../.work/histories"}
[ $# -gt 0 ] && shift
[ $# -gt 0 ] || set -- pr-merge squash linear-conventional

mkdir -p "$TARGET"
TARGET=$(CDPATH='' cd -- "$TARGET" && pwd)

n=0
# Commit <text> into notes.md of <dir> with <subject>, one day after the previous commit.
commit() { # dir subject text
  n=$((n + 1))
  printf '%s\n' "$3" >> "$1/notes.md"
  git -C "$1" add -A
  GIT_AUTHOR_DATE="2025-$(printf %02d $((n / 28 + 1)))-$(printf %02d $((n % 28 + 1)))T12:00:00Z" \
  GIT_COMMITTER_DATE="2025-$(printf %02d $((n / 28 + 1)))-$(printf %02d $((n % 28 + 1)))T12:00:00Z" \
    git -C "$1" commit -q -m "$2"
}
# Merge <branch> into main of <dir> with a merge commit and <subject>.
merge() { # dir branch subject
  n=$((n + 1))
  git -C "$1" switch -q main
  GIT_AUTHOR_DATE="2025-$(printf %02d $((n / 28 + 1)))-$(printf %02d $((n % 28 + 1)))T12:00:00Z" \
  GIT_COMMITTER_DATE="2025-$(printf %02d $((n / 28 + 1)))-$(printf %02d $((n % 28 + 1)))T12:00:00Z" \
    git -C "$1" merge -q --no-ff -m "$3" "$2"
}
init_repo() { # dir
  rm -rf "$1"
  mkdir -p "$1"
  git -C "$1" init -q -b main
  git -C "$1" config user.name "groma-fixture"
  git -C "$1" config user.email "fixture@groma.invalid"
  git -C "$1" config commit.gpgsign false
  n=0
}

for name in "$@"; do
  dest="$TARGET/$name"
  case "$name" in
    pr-merge)
      init_repo "$dest"
      commit "$dest" "Initial commit" "start"
      for i in 1 2 3 4 5 6; do
        git -C "$dest" switch -q -c "feature-$i"
        commit "$dest" "feat: add feature $i" "feature $i"
        merge "$dest" "feature-$i" "Merge pull request #$i from dev/feature-$i"
      done
      commit "$dest" "docs: update readme" "readme"
      git -C "$dest" switch -q -c release
      commit "$dest" "chore: prepare release" "release"
      merge "$dest" release "Merge branch 'release'"
      git -C "$dest" switch -q -c upstream
      commit "$dest" "Sync with upstream" "upstream"
      merge "$dest" upstream "Sync upstream into main"
      ;;
    squash)
      init_repo "$dest"
      commit "$dest" "Initial commit" "start"
      commit "$dest" "feat: add cart (#1)" "cart"
      commit "$dest" "fix: cart total (#2)" "total"
      commit "$dest" "feat(checkout): add checkout (#3)" "checkout"
      commit "$dest" "docs: describe checkout (#4)" "docs"
      commit "$dest" "chore: bump dependencies (#5)" "deps"
      commit "$dest" "Fix typo" "typo"
      commit "$dest" "feat: add search (#6)" "search"
      commit "$dest" "refactor: split cart (#7)" "split"
      commit "$dest" "test: cart totals (#8)" "tests"
      ;;
    linear-conventional)
      init_repo "$dest"
      commit "$dest" "Initial commit" "start"
      commit "$dest" "feat: add cart" "cart"
      commit "$dest" "fix(cart): round totals" "round"
      commit "$dest" "docs: describe the cart" "docs"
      commit "$dest" "chore: bump dependencies" "deps"
      commit "$dest" "feat!: drop node 18" "node"
      commit "$dest" "test: cart totals" "tests"
      commit "$dest" "refactor(cart): split module" "split"
      commit "$dest" "ci: run tests on pull requests" "ci"
      commit "$dest" "perf: cache totals" "cache"
      ;;
    *) echo "unknown history: $name" >&2; exit 1 ;;
  esac
  echo "$dest"
done
