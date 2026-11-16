#!/bin/sh
# Check change names against the groma convention <type><N>-<slug>, and print
# migration suggestions for names in the old format <type><NNN>-<slug>.
#
# Usage: check-conventions.sh [--root <project dir>] [--suggest-migration]
#
# A name conforms when it is a known type letter, a number without leading zeros
# and a kebab-case slug (c4-export, m3-checkout, m3-fix-rounding). Not checked:
# names listed in .groma/conventions-baseline.txt (changes that existed before
# the rule) and archived changes, which nobody renames. An active name in the
# old format, <type>0<NN>-<slug> with a known type or the old d (c017-export,
# m004-v0-4), is accepted with an INFO line: a project that was set up with the
# old rule stays green until its baseline is written.
# Duplicates: <type><N> for every type but m, compared as numbers (c005-a and c5-b
# collide); the full name for m, because several changes share a milestone number.
# A section "## M<N>: <title>" of docs/roadmap.md needs the marker block that
# roadmap.sh fills.
#
# Output: INFO<TAB><name><TAB>old name format, accepted: ...
#         VIOLATION<TAB><name><TAB>suggest <name>
#         DUPLICATE<TAB><id><TAB><names><TAB>keep <name>[, rename <name> to <new name>]
#         MARKERS<TAB>M<N><TAB>add "<!-- groma:changes m<N> -->" and "<!-- /groma:changes -->" ...
#         then "conventions: ok" or "conventions: <n> problem(s)".
# With --suggest-migration (no check, always exit 0):
#         MIGRATE<TAB><old name><TAB><new name>      per active change in the old format;
#                                                    a child with "Milestone: mNNN" becomes m<N>-...
#         MIGRATE<TAB><old name><TAB>roadmap section M<N>   per active umbrella milestone
#         SECTION<TAB>M<N><TAB><old name>            per umbrella milestone, active or archived,
#                                                    followed by the section text and an empty line
#         then "migration: <n> name(s), <n> section(s)".
# Exit codes: 0 ok, 1 violations, duplicates or missing marker blocks, 2 usage error.
# Read-only: nothing is renamed and no file is written.
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=SCRIPTDIR/lib-changes.sh
. "$HERE/lib-changes.sh"

ROOT=.
MIGRATE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=$2; shift 2 ;;
    --suggest-migration) MIGRATE=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

TAB=$(printf '\t')
TYPES=$(config_types "$ROOT")
letters=""
for t in $TYPES; do letters="$letters|${t%%:*}"; done
letters=${letters#|}
DIR=$(changes_dir "$ROOT")
LIST=$(list_changes "$DIR")
ROADMAP="$ROOT/docs/roadmap.md"
bad=0

guess_type() { # first word of a non-conforming name -> type letter
  case "$1" in
    fix|bugfix|hotfix|bug) echo f ;;
    refactor|cleanup|chore) echo r ;;
    spike|research|poc|explore) echo s ;;
    *) echo c ;;
  esac
}

# <type><N> of a typed name with the number as a number: c005-x -> c5. Nothing for other names.
id_key() { echo "$1" | sed -nE 's/^([a-z]+)0*([0-9]+)-.*/\1\2/p'; }

# All ids in use, one "<key><TAB><name>" per line.
KEYS=$(for n in $(printf '%s\n' "$LIST" | cut -f1); do
  k=$(id_key "$n")
  [ -z "$k" ] || printf '%s\t%s\n' "$k" "$n"
done)

TAKEN=""   # ids suggested during this run, so two suggestions never collide

id_used() { # id [name to ignore] -> 0 if another change or an earlier suggestion uses it
  if printf '%s\n' "$KEYS" | awk -F "$TAB" -v id="$1" -v self="${2:-}" '$1 == id && $2 != self { f = 1 } END { exit !f }'; then
    return 0
  fi
  case " $TAKEN " in *" $1 "*) return 0 ;; esac
  return 1
}

# alloc <type> [wanted-number] [name to ignore]: sets ALLOC to a free id, keeping
# the wanted number when it is free. Not called via $(...) so TAKEN survives.
alloc() {
  a_ty=$1 a_want=${2:-} a_self=${3:-}
  if [ -n "$a_want" ]; then
    ALLOC="$a_ty$a_want"
    if ! id_used "$ALLOC" "$a_self"; then TAKEN="$TAKEN $ALLOC"; return; fi
  fi
  if ! a_next=$(sh "$HERE/next-change-id.sh" "$a_ty" --root "$ROOT" 2>/dev/null); then
    ALLOC="${a_ty}?"; return
  fi
  a_num=${a_next#"$a_ty"}
  ALLOC="$a_ty$a_num"
  while id_used "$ALLOC"; do a_num=$((a_num + 1)); ALLOC="$a_ty$a_num"; done
  TAKEN="$TAKEN $ALLOC"
}

is_type() { for t in $TYPES; do [ "${t%%:*}" = "$1" ] && return 0; done; return 1; }

conforms() { echo "$1" | grep -Eq "^(${letters})[1-9][0-9]*-[a-z0-9]+(-[a-z0-9]+)*\$"; }

# the old format: a known type or the old d, three digits with a leading zero, a slug
old_format() { echo "$1" | grep -Eq "^(${letters}|d)0[0-9][0-9]-[a-z0-9]+(-[a-z0-9]+)*\$"; }

# a slug in kebab-case from any text: other characters become dashes, no dash at either end
kebab() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'; }

# --- migration suggestions ---------------------------------------------------
goal_of() { # proposal path
  [ -f "$1" ] || { echo "-"; return; }
  g=$(sed -nE 's/^\*\*Goal:\*\*[ ]*//p' "$1" | head -n 1)
  [ -n "$g" ] || g=$(awk '/^## Why/ { f = 1; next } f && NF { print; exit }' "$1")
  echo "${g:--}"
}

# Checklist of an umbrella milestone: the tasks below a "Release gate" heading
# with their state; without such a heading the open tasks. Task numbers are dropped.
gate_of() { # tasks path
  [ -f "$1" ] || return 0
  awk '
    function item(s) { sub(/^[ \t]*- \[.\][ \t]*/, "", s); sub(/^[0-9]+(\.[0-9]+)*\.?[ \t]+/, "", s); return s }
    /^#+ / { ing = (tolower($0) ~ /release gate/); if (ing) has = 1; next }
    /^[ \t]*- \[[ xX]\]/ {
      open = ($0 ~ /^[ \t]*- \[ \]/)
      if (ing) gate[++g] = "- [" (open ? " " : "x") "] " item($0)
      if (open) rest[++r] = "- [ ] " item($0)
    }
    END { if (has) { for (i = 1; i <= g; i++) print gate[i] } else { for (i = 1; i <= r; i++) print rest[i] } }' "$1"
}

if [ "$MIGRATE" -eq 1 ]; then
  names=0 sections=0
  while IFS="$TAB" read -r n loc path <&3; do
    [ -n "$n" ] || continue
    [ "$loc" = active ] || continue
    if is_umbrella "$n"; then
      printf 'MIGRATE%s%s%sroadmap section M%s\n' "$TAB" "$n" "$TAB" "$(milestone_of "$n")"
      names=$((names + 1))
      continue
    fi
    if conforms "$n"; then continue; fi
    ty=$(echo "$n" | sed -nE 's/^([a-z]+)[0-9]+-.+/\1/p')
    [ -n "$ty" ] || continue                      # unprefixed brownfield names keep their names
    num=$(echo "$n" | sed -nE 's/^[a-z]+0*([0-9]+)-.*/\1/p')
    slug=${n#*-}
    ms=""
    [ ! -f "$path/proposal.md" ] || ms=$(sed -nE '1,5s/^Milestone:[[:space:]]*m0*([0-9]+).*/\1/p' "$path/proposal.md" | head -n 1)
    if [ -n "$ms" ]; then
      case "$ty" in
        f) new="m$ms-fix-$slug" ;;
        s) new="m$ms-spike-$slug" ;;
        r) new="m$ms-refactor-$slug" ;;
        *) new="m$ms-$slug" ;;
      esac
    elif is_type "$ty"; then
      alloc "$ty" "$num" "$n"; new="$ALLOC-$slug"
    else
      alloc c; new="$ALLOC-$slug"                 # a removed type such as d becomes a change
    fi
    printf 'MIGRATE%s%s%s%s\n' "$TAB" "$n" "$TAB" "$new"
    names=$((names + 1))
  done 3<<EOF
$LIST
EOF
  while IFS="$TAB" read -r n _ path <&3; do
    [ -n "$n" ] || continue
    if ! is_umbrella "$n"; then continue; fi
    ms=$(milestone_of "$n")
    printf 'SECTION%sM%s%s%s\n' "$TAB" "$ms" "$TAB" "$n"
    printf '## M%s: %s\n\n**Goal:** %s\n\n**Release gate:**\n' "$ms" "${n#*-}" "$(goal_of "$path/proposal.md")"
    gate_of "$path/tasks.md"
    printf '\n<!-- groma:changes m%s -->\n<!-- /groma:changes -->\n\n' "$ms"
    sections=$((sections + 1))
  done 3<<EOF
$(printf '%s\n' "$LIST" | sort)
EOF
  echo "migration: $names name(s), $sections section(s)"
  exit 0
fi

# --- names -------------------------------------------------------------------
VIOLATED=" "   # active names with a VIOLATION line; the duplicate check leaves them alone
old=0
while IFS="$TAB" read -r n loc _ <&3; do
  [ -n "$n" ] || continue
  [ "$loc" = active ] || continue                # archived changes are never renamed
  if in_baseline "$n"; then continue; fi
  if conforms "$n"; then continue; fi
  if old_format "$n"; then
    printf 'INFO%s%s%sold name format, accepted: add it to .groma/conventions-baseline.txt; new names with --suggest-migration\n' "$TAB" "$n" "$TAB"
    old=$((old + 1))
    continue
  fi
  lower=$(echo "$n" | tr '[:upper:]_' '[:lower:]-')
  ty=$(echo "$lower" | sed -nE 's/^([a-z]+)[0-9]+-.*/\1/p')
  num=$(echo "$lower" | sed -nE 's/^[a-z]+0*([0-9]+)-.*/\1/p')
  [ "$num" != 0 ] || num=""                      # 0 is no id
  slug=$(kebab "${lower#*-}")
  if [ "$ty" = m ] && is_type m; then
    # change of a milestone in the wrong format: the number is the milestone, shared by its changes
    if [ -z "$num" ]; then num=$(sh "$HERE/next-change-id.sh" m --root "$ROOT" 2>/dev/null | sed 's/^m//'); fi
    case "$slug" in
      '') new="m$num-<slug>" ;;
      spike|fix|refactor) new="m$num-$slug-<slug>" ;;   # a type word still needs a slug
      *) new="m$num-$slug" ;;
    esac
  elif [ -n "$ty" ] && is_type "$ty"; then
    # typed name in the wrong format (uppercase, zero padding): keep its number when free
    alloc "$ty" "$num" "$n"; new="$ALLOC-${slug:-<slug>}"
  elif echo "$lower" | grep -Eq '^[a-z][0-9]+-'; then
    # one letter and a number, but not a type (the removed d): a change
    alloc c; new="$ALLOC-${slug:-<slug>}"
  else
    slug=$(kebab "$lower")
    first=${slug%%-*}
    ty=$(guess_type "$first")
    case "$first" in
      fix|bugfix|hotfix|bug|refactor|cleanup|chore|spike|research|poc|explore|add|feat|feature)
        [ "$first" != "$slug" ] && slug=${slug#"$first"-} ;;
    esac
    alloc "$ty"; new="$ALLOC-${slug:-<slug>}"
  fi
  printf 'VIOLATION%s%s%ssuggest %s\n' "$TAB" "$n" "$TAB" "$new"
  VIOLATED="$VIOLATED$n "
  bad=$((bad + 1))
done 3<<EOF
$LIST
EOF

# --- duplicate ids -----------------------------------------------------------
dups=$(printf '%s\n' "$KEYS" | cut -f1 | grep -E "^(${letters})[0-9]+\$" | grep -v '^m[0-9]' | sort | uniq -d || true)
for id in $dups; do
  entries=$(printf '%s\n' "$KEYS" | awk -F "$TAB" -v id="$id" '$1 == id { print $2 }' | while IFS= read -r en; do
    printf '%s\n' "$LIST" | awk -F "$TAB" -v n="$en" '$1 == n'
  done | sort -u)
  names=$(printf '%s\n' "$entries" | cut -f1 | tr '\n' ' ')
  # keep the archived one (archives are immutable); else an active name without a
  # VIOLATION line before one with it, the earliest created first, then alphabetical
  keep=$(printf '%s\n' "$entries" | awk -F "$TAB" '$2 == "archive" { print $1; exit }')
  if [ -z "$keep" ]; then
    keep=$(printf '%s\n' "$entries" | while IFS="$TAB" read -r en _ ep; do
      c=$(sed -n 's/^created:[ ]*//p' "$ep/.openspec.yaml" 2>/dev/null | head -n 1)
      v=0; case "$VIOLATED" in (*" $en "*) v=1 ;; esac
      printf '%s\t%s\t%s\n' "$v" "${c:-9999-99-99}" "$en"
    done | sort | head -n 1 | cut -f3)
  fi
  sugg=""
  for en in $(printf '%s\n' "$entries" | awk -F "$TAB" -v k="$keep" '$2 == "active" && $1 != k { print $1 }'); do
    # a name with a VIOLATION line has its new name there; a second one would contradict it
    case "$VIOLATED" in *" $en "*) sugg="$sugg, $en: see its VIOLATION line"; continue ;; esac
    ty=${id%%[0-9]*}
    alloc "$ty"
    sugg="$sugg, rename $en to $ALLOC-${en#*-}"
  done
  printf 'DUPLICATE%s%s%s%s%skeep %s%s\n' "$TAB" "$id" "$TAB" "${names% }" "$TAB" "$keep" "$sugg"
  bad=$((bad + 1))
done
# milestone members share their number, so only an equal full name is a duplicate
for n in $(printf '%s\n' "$LIST" | cut -f1 | grep -E '^m[0-9]+-' | sort | uniq -d || true); do
  printf 'DUPLICATE%s%s%s%s %s%skeep the archived %s, give the active change another slug\n' "$TAB" "$n" "$TAB" "$n" "$n" "$TAB" "$n"
  bad=$((bad + 1))
done

# --- roadmap sections without a marker block ---------------------------------
if [ -f "$ROADMAP" ]; then
  unmarked=$(awk "$ROADMAP_AWK"'
    function flush() { if (n != "" && !(n in marked)) print n; n = "" }
    /^##? / { flush() }
    milestone_heading($0) != "" { n = milestone_heading($0); next }
    marker_open($0) != "" { marked[marker_open($0)] = 1 }
    END { flush() }' "$ROADMAP")
  for ms in $unmarked; do
    printf 'MARKERS%sM%s%sadd the lines "<!-- groma:changes m%s -->" and "<!-- /groma:changes -->" to the section in docs/roadmap.md, then run roadmap.sh\n' "$TAB" "$ms" "$TAB" "$ms"
    bad=$((bad + 1))
  done
fi

if [ "$bad" -gt 0 ]; then
  echo "conventions: $bad problem(s)"
  exit 1
fi
echo "conventions: ok"
