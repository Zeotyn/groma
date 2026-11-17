#!/bin/sh
# Acceptance test of the effect task on go-no-db (tests/evals/effect/go-no-db.md).
# The agent never sees it. Builds outside the project, so nothing is left behind.
# Usage: go-no-db.sh <project-dir>; exit 0 when every check passes.
# Requires: go gofmt
set -u
P=$1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
no() { echo "   FAIL  $1"; fails=$((fails + 1)); }

(cd "$P" && GOTOOLCHAIN=local GOFLAGS=-mod=readonly go build -o "$tmp/wordcount" .) >"$tmp/build.log" 2>&1 \
  || { no "go build (see below)"; cat "$tmp/build.log"; exit 1; }
input='one two
three  four five

six
'
words=$(printf '%s' "$input" | "$tmp/wordcount")
lines=$(printf '%s' "$input" | "$tmp/wordcount" -l)
[ "$words" = 6 ] || no "without -l: expected 6, got '$words'"
[ "$lines" = 4 ] || no "with -l: expected 4, got '$lines'"
unformatted=$(cd "$P" && gofmt -l .)
[ -z "$unformatted" ] || no "gofmt: $unformatted"
# stdlib only: the project has no dependencies
! grep -q '^require' "$P/go.mod" || no "go.mod gained a dependency"
[ "$fails" -eq 0 ]
