#!/bin/sh
# Check change names against the groma convention <type><NNN>-<slug>.
#
# Usage: check-conventions.sh [--root <project dir>]
# Names listed in .groma/conventions-baseline.txt (changes that existed before
# groma was introduced) are exempt.
# Output: VIOLATION<TAB><name><TAB>suggest <name>
#         DUPLICATE<TAB><id><TAB><names><TAB>keep <name>[, rename <name> to <new name>]
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

TAKEN=""   # ids suggested during this run, so two suggestions never collide

id_used() { # id -> 0 if an existing change or an earlier suggestion uses it
  printf '%s\n' "$LIST" | cut -f1 | grep -q "^$1-" && return 0
  case " $TAKEN " in *" $1 "*) return 0 ;; esac
  return 1
}

pad() { printf "%s%0${DIGITS}d" "$1" "$2"; }

# alloc <type> [wanted-number]: sets ALLOC to a free id, keeping the wanted
# number when it is free. Not called via $(...) so TAKEN survives.
alloc() {
  a_ty=$1 a_want=${2:-}
  if [ -n "$a_want" ]; then
    ALLOC=$(pad "$a_ty" "$a_want")
    if ! id_used "$ALLOC"; then TAKEN="$TAKEN $ALLOC"; return; fi
  fi
  if ! a_next=$(sh "$HERE/next-change-id.sh" "$a_ty" --root "$ROOT" 2>/dev/null); then
    ALLOC="${a_ty}???"; return
  fi
  a_num=$(echo "$a_next" | sed -E 's/^[a-z]+0*//'); a_num=${a_num:-1}
  ALLOC=$(pad "$a_ty" "$a_num")
  while id_used "$ALLOC"; do a_num=$((a_num + 1)); ALLOC=$(pad "$a_ty" "$a_num"); done
  TAKEN="$TAKEN $ALLOC"
}

is_type() { for t in $TYPES; do [ "${t%%:*}" = "$1" ] && return 0; done; return 1; }

for n in $(printf '%s\n' "$LIST" | cut -f1); do
  [ -n "$n" ] || continue
  if [ -f "$BASELINE" ] && grep -qx "$n" "$BASELINE"; then continue; fi
  if echo "$n" | grep -Eq "^(${letters})[0-9]{${DIGITS}}-[a-z0-9]+(-[a-z0-9]+)*\$"; then continue; fi
  lower=$(echo "$n" | tr '[:upper:]_' '[:lower:]-')
  ty=$(echo "$lower" | sed -nE 's/^([a-z]+)[0-9]+-.*/\1/p')
  if [ -n "$ty" ] && is_type "$ty"; then
    # typed name in the wrong format (uppercase, missing padding): keep its number when free
    want=$(echo "$lower" | sed -nE 's/^[a-z]+0*([0-9]+)-.*/\1/p')
    slug=${lower#*-}
    alloc "$ty" "$want"; id=$ALLOC
  else
    first=${lower%%-*}
    ty=$(guess_type "$first")
    slug=$lower
    case "$first" in
      fix|bugfix|hotfix|bug|refactor|cleanup|chore|docs|doc|documentation|spike|research|poc|explore|milestone|release|epic|add|feat|feature)
        [ "$first" != "$lower" ] && slug=${lower#"$first"-} ;;
    esac
    alloc "$ty"; id=$ALLOC
  fi
  printf 'VIOLATION%s%s%ssuggest %s-%s\n' "$TAB" "$n" "$TAB" "$id" "$slug"
  bad=$((bad + 1))
done

dups=$(printf '%s\n' "$LIST" | cut -f1 | sed -nE "s/^((${letters})[0-9]+)-.*/\\1/p" | sort | uniq -d)
for id in $dups; do
  entries=$(printf '%s\n' "$LIST" | awk -F "$TAB" -v id="$id" 'index($1, id "-") == 1')
  names=$(printf '%s\n' "$entries" | cut -f1 | tr '\n' ' ')
  # keep the archived one (archives are immutable); else the earliest created, then alphabetical
  keep=$(printf '%s\n' "$entries" | awk -F "$TAB" '$2 == "archive" { print $1; exit }')
  if [ -z "$keep" ]; then
    keep=$(printf '%s\n' "$entries" | while IFS="$TAB" read -r en _ ep; do
      c=$(sed -n 's/^created:[ ]*//p' "$ep/.openspec.yaml" 2>/dev/null | head -n 1)
      printf '%s\t%s\n' "${c:-9999-99-99}" "$en"
    done | sort | head -n 1 | cut -f2)
  fi
  sugg=""
  for en in $(printf '%s\n' "$entries" | awk -F "$TAB" -v k="$keep" '$2 == "active" && $1 != k { print $1 }'); do
    ty=${id%%[0-9]*}
    alloc "$ty"
    sugg="$sugg, rename $en to $ALLOC-${en#*-}"
  done
  printf 'DUPLICATE%s%s%s%s%skeep %s%s\n' "$TAB" "$id" "$TAB" "${names% }" "$TAB" "$keep" "$sugg"
  bad=$((bad + 1))
done

if [ "$bad" -gt 0 ]; then
  echo "conventions: $bad problem(s)"
  exit 1
fi
echo "conventions: ok"
