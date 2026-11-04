#!/bin/sh
# Print the next free change id for a type, e.g. "c004".
#
# Usage: next-change-id.sh <type> [--root <project dir>]
# Counts active and archived changes; numbers are never reused.
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
[ "$known" -eq 1 ] || { echo "unknown change type '$TYPE' (known: $(config_types "$ROOT"))" >&2; exit 2; }

DIGITS=$(config_digits "$ROOT")
max=0
for n in $(list_changes "$(changes_dir "$ROOT")" | cut -f1); do
  num=$(echo "$n" | sed -nE "s/^${TYPE}([0-9]+)-.*/\\1/p")
  [ -n "$num" ] || continue
  num=$(echo "$num" | sed 's/^0*//'); num=${num:-0}
  [ "$num" -gt "$max" ] && max=$num
done
printf "%s%0${DIGITS}d\n" "$TYPE" $((max + 1))
