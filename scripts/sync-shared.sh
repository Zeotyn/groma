#!/bin/sh
# Copy every shared source over its vendored copies (ADR 0051). Dev only, not shipped.
#
# Usage: scripts/sync-shared.sh [--check]
#   reads scripts/shared-files.txt: lines "<source> -> <consumer>", paths from
#   the repository root, # comments and blank lines ignored
#   --check   copy nothing, report the copies that differ
#
# Output, tab-separated:
#   copied<TAB><consumer>          (--check: differs<TAB><consumer><TAB><source>)
#   summary<TAB>copied=<n>          (--check: summary<TAB>differs=<n>)
# Exit 0; --check exits 1 when a copy differs or is missing; a missing source
# or a malformed line exits 1; usage errors exit 2.
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
MANIFEST="$ROOT/scripts/shared-files.txt"
CHECK=0
case "${1:-}" in
  '') ;;
  --check) CHECK=1 ;;
  *) echo "usage: $0 [--check]" >&2; exit 2 ;;
esac
[ -f "$MANIFEST" ] || { echo "missing: $MANIFEST" >&2; exit 1; }

set -f
TAB=$(printf '\t')
n=0 bad=0 lineno=0
while IFS= read -r line || [ -n "$line" ]; do
  lineno=$((lineno + 1))
  case "$line" in ''|'#'*) continue ;; esac
  # shellcheck disable=SC2086
  set -- $line
  if [ $# -ne 3 ] || [ "$2" != "->" ]; then
    echo "shared-files.txt:$lineno: expected '<source> -> <consumer>'" >&2
    exit 1
  fi
  src=$1 dst=$3
  [ -f "$ROOT/$src" ] || { echo "shared-files.txt:$lineno: source missing: $src" >&2; exit 1; }
  if [ -f "$ROOT/$dst" ] && cmp -s "$ROOT/$src" "$ROOT/$dst"; then
    continue
  fi
  n=$((n + 1))
  if [ "$CHECK" -eq 1 ]; then
    printf 'differs%s%s%s%s\n' "$TAB" "$dst" "$TAB" "$src"
    bad=1
  else
    mkdir -p "$(dirname "$ROOT/$dst")"
    cp "$ROOT/$src" "$ROOT/$dst"
    printf 'copied%s%s\n' "$TAB" "$dst"
  fi
done < "$MANIFEST"

if [ "$CHECK" -eq 1 ]; then
  printf 'summary%sdiffers=%s\n' "$TAB" "$n"
else
  printf 'summary%scopied=%s\n' "$TAB" "$n"
fi
exit "$bad"
