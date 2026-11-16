#!/bin/sh
# Print the next free change id for a type, e.g. "c4".
#
# Usage: next-change-id.sh <type> [--root <project dir>]
# c, f, s, r and custom types: one above the highest number of that type among
# active and archived changes; old zero-padded names (c016-x) count, numbers are
# never reused. The output has no zero padding.
# m: the next free milestone number (m5), one above the highest N among the
# "## M<N>" headings of docs/roadmap.md and the m<N>- names, active and archived.
# A change that joins an existing milestone needs no new id: name it m<N>-<slug>.
# Exit codes: 0, 2 usage error or unknown type.
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=SCRIPTDIR/lib-changes.sh
. "$HERE/lib-changes.sh"

ROOT=.
TYPE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=$2; shift 2 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) TYPE=$1; shift ;;
  esac
done
[ -n "$TYPE" ] || { echo "usage: $0 <type> [--root <dir>]" >&2; exit 2; }

known=0
for t in $(config_types "$ROOT"); do
  [ "${t%%:*}" = "$TYPE" ] && known=1
done
if [ "$known" -ne 1 ]; then
  echo "unknown change type '$TYPE' (known: $(config_types "$ROOT"))" >&2
  [ "$TYPE" != d ] || echo "there is no docs type: docs belong to the change that causes them" >&2
  exit 2
fi

max=0
if [ "$TYPE" = m ] && [ -f "$ROOT/docs/roadmap.md" ]; then
  headings=$(sed -nE 's/^## M0*([0-9]+)([^0-9].*)?$/\1/p' "$ROOT/docs/roadmap.md")
  for num in $headings; do
    [ "$num" -gt "$max" ] && max=$num
  done
fi
for n in $(list_changes "$(changes_dir "$ROOT")" | cut -f1); do
  num=$(echo "$n" | sed -nE "s/^${TYPE}([0-9]+)-.*/\\1/p")
  [ -n "$num" ] || continue
  num=$(echo "$num" | sed 's/^0*//'); num=${num:-0}
  [ "$num" -gt "$max" ] && max=$num
done
printf '%s%d\n' "$TYPE" $((max + 1))
