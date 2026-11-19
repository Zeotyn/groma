#!/bin/sh
# Record a project's setup as the first commit of its repository.
#
# Usage: first-commit.sh <project> <groma version>
#
# Only in a repository without any commit: stages what `git status --porcelain`
# lists below <project> (so .gitignore is honoured) and commits it with the
# user's git identity and the message `chore: set up project with groma <version>`.
# Never sets an identity, never uses --no-verify.
#
# Output, tab-separated, one line:
#   commit<TAB>done<TAB><short hash>
#   commit<TAB>skipped<TAB>repository has commits|nothing to commit
#   commit<TAB>no-identity<TAB><commands that set one and commit>
#   commit<TAB>no-git<TAB>git not found on PATH
# The identity check reads `git config user.name` and `user.email` only; an
# identity given by GIT_AUTHOR_* or GIT_COMMITTER_* alone counts as none.
# Exit 0 for done and skipped; 3 without identity (nothing committed); 1 when
# git is not on PATH, <project> is not in a git work tree, or staging or the
# commit fails (git's error is passed on unchanged); usage errors exit 2.
set -eu

if [ $# -ne 2 ] || [ ! -d "$1" ] || [ -z "$2" ]; then
  echo "usage: first-commit.sh <project> <groma version>" >&2
  exit 2
fi
P=$1 VERSION=$2

if ! command -v git >/dev/null 2>&1; then
  printf 'commit\tno-git\tgit not found on PATH\n'
  exit 1
fi

git -C "$P" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repository: $P" >&2; exit 1; }
if git -C "$P" rev-parse -q --verify HEAD >/dev/null 2>&1; then
  printf 'commit\tskipped\trepository has commits\n'
  exit 0
fi
if [ -z "$(git -C "$P" config user.name || true)" ] || [ -z "$(git -C "$P" config user.email || true)" ]; then
  printf 'commit\tno-identity\tgit config user.name "<name>"; git config user.email "<email>"; git add -A .; git commit -m "chore: set up project with groma %s"\n' "$VERSION"
  exit 3
fi
if [ -z "$(git -C "$P" status --porcelain -- .)" ]; then
  printf 'commit\tskipped\tnothing to commit\n'
  exit 0
fi

MSG=$(mktemp)
trap 'rm -f "$MSG"' EXIT
printf 'chore: set up project with groma %s\n' "$VERSION" > "$MSG"
git -C "$P" add -A -- . || exit 1
# the pathspec keeps files staged outside <project> (a parent repository) out of the commit
git -C "$P" commit -q -F "$MSG" -- . || exit 1
printf 'commit\tdone\t%s\n' "$(git -C "$P" rev-parse --short HEAD)"
