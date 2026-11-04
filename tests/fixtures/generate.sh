#!/bin/sh
# Build fixture repositories with deterministic git history.
#
# Fixture sources live in tests/fixtures/src/<name>/<YYYY-MM-DD>/...
# Each date folder is copied on top of the previous state and committed at
# that date, in sorted order. A fixture without date folders becomes an empty
# git repository without commits.
#
# Usage: tests/fixtures/generate.sh [target-dir] [fixture...]
#   target-dir defaults to tests/.work/fixtures
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
SRC="$HERE/src"
TARGET=${1:-"$HERE/../.work/fixtures"}
[ $# -gt 0 ] && shift

mkdir -p "$TARGET"
TARGET=$(CDPATH='' cd -- "$TARGET" && pwd)

if [ $# -eq 0 ]; then
  for d in "$SRC"/*/; do
    d=${d%/}
    set -- "$@" "${d##*/}"
  done
fi

for name in "$@"; do
  src="$SRC/$name"
  dest="$TARGET/$name"
  if [ ! -d "$src" ]; then
    echo "unknown fixture: $name" >&2
    exit 1
  fi
  rm -rf "$dest"
  mkdir -p "$dest"
  git -C "$dest" init -q -b main
  git -C "$dest" config user.name "groma-fixture"
  git -C "$dest" config user.email "fixture@groma.invalid"
  git -C "$dest" config commit.gpgsign false
  # globs expand in sorted order, so date folders are applied chronologically
  for stepdir in "$src"/*/; do
    [ -d "$stepdir" ] || continue
    stepdir=${stepdir%/}
    step=${stepdir##*/}
    case "$step" in
      [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
      *) continue ;;
    esac
    cp -R "$src/$step/." "$dest/"
    git -C "$dest" add -A
    GIT_AUTHOR_DATE="${step}T12:00:00Z" GIT_COMMITTER_DATE="${step}T12:00:00Z" \
      git -C "$dest" commit -q -m "fixture $name: state of $step"
  done
  echo "$dest"
done
