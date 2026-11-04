#!/bin/sh
# Check change names against the groma convention <type><NNN>-<slug>.
#
# Usage: check-conventions.sh [--root <project dir>]
# Names listed in .groma/conventions-baseline.txt (changes that existed before
# groma was introduced) are exempt.
# Output: VIOLATION<TAB><name><TAB>suggest <name>  /  DUPLICATE<TAB><id><TAB><names>
# Exit code 1 when violations or duplicates exist. Read-only.
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=SCRIPTDIR/lib-changes.sh
. "$HERE/lib-changes.sh"

ROOT=.
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=$2; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

TAB=$(printf '\t')
TYPES=$(config_types "$ROOT")
DIGITS=$(config_digits "$ROOT")
letters=""
for t in $TYPES; do letters="$letters|${t%%:*}"; done
letters=${letters#|}
BASELINE="$ROOT/.groma/conventions-baseline.txt"
DIR=$(changes_dir "$ROOT")
LIST=$(list_changes "$DIR")
bad=0

guess_type() { # first word of a non-conforming name -> type letter
  case "$1" in
    fix|bugfix|hotfix|bug) echo f ;;
    refactor|cleanup|chore) echo r ;;
    docs|doc|documentation) echo d ;;
    spike|research|poc|explore) echo s ;;
    milestone|release|epic) echo m ;;
    *) echo c ;;
  esac
}

for n in $(printf '%s\n' "$LIST" | cut -f1); do
  [ -n "$n" ] || continue
  if [ -f "$BASELINE" ] && grep -qx "$n" "$BASELINE"; then continue; fi
  if echo "$n" | grep -Eq "^(${letters})[0-9]{${DIGITS}}-[a-z0-9]+(-[a-z0-9]+)*\$"; then continue; fi
  first=${n%%-*}
  ty=$(guess_type "$first")
  slug=$n
  [ "$ty" != c ] || [ "$first" = add ] || [ "$first" = feat ] || [ "$first" = feature ] || first=""
  [ -n "$first" ] && [ "$first" != "$n" ] && slug=${n#"$first"-}
  slug=$(echo "$slug" | tr 'A-Z_' 'a-z-' | sed -E 's/^[a-z]+[0-9]+-//')
  next=$(sh "$HERE/next-change-id.sh" "$ty" --root "$ROOT" 2>/dev/null || echo "${ty}???")
  printf 'VIOLATION%s%s%ssuggest %s-%s\n' "$TAB" "$n" "$TAB" "$next" "$slug"
  bad=$((bad + 1))
done

dups=$(printf '%s\n' "$LIST" | cut -f1 | sed -nE "s/^((${letters})[0-9]+)-.*/\\1/p" | sort | uniq -d)
for id in $dups; do
  names=$(printf '%s\n' "$LIST" | cut -f1 | grep -E "^${id}-" | tr '\n' ' ')
  printf 'DUPLICATE%s%s%s%s\n' "$TAB" "$id" "$TAB" "${names% }"
  bad=$((bad + 1))
done

if [ "$bad" -gt 0 ]; then
  echo "conventions: $bad problem(s)"
  exit 1
fi
echo "conventions: ok"
