#!/bin/sh
# Shared helpers for the change-convention scripts. Source, do not execute.
# shellcheck shell=sh

DEFAULT_TYPES="m:milestone c:change f:fix s:spike r:refactor"

# Read a scalar from .groma/config.yaml below the global $ROOT.
cfg_value() { # key default [section]
  v=""
  # shellcheck disable=SC2153  # ROOT is set by the sourcing script
  [ -f "$ROOT/.groma/config.yaml" ] && v=$(awk -v k="$1" -v sec="${3:-reminders}" '
    function ind(s) { match(s, /^ */); return RLENGTH }
    /^[ ]*#/ || /^[ ]*$/ { next }
    { i = ind($0); l = $0; sub(/^ */, "", l); sub(/[ ]+#.*/, "", l); sub(/[ \t]+$/, "", l)
      if (inr && i == 0) inr = 0
      if (l == sec ":" && i == 0) { inr = 1; next }
      if (inr && index(l, k ":") == 1) { sub(/^[^:]*:[ ]*/, "", l); gsub(/["\047]/, "", l); print l; exit } }' "$ROOT/.groma/config.yaml")
  echo "${v:-$2}"
}

# Is the next action on for the project in the global $ROOT? next.hook in
# .groma/config.yaml decides: on or off. Unset, empty ("hook:") or auto follows the user's global
# flag file ~/.claude/.groma-next-always, which is only read, never written.
# Any other value counts as off.
next_on() {
  case "$(cfg_value hook auto next)" in
    on) return 0 ;;
    auto) [ -n "${HOME:-}" ] && [ -e "$HOME/.claude/.groma-next-always" ] ;;
    *) return 1 ;;
  esac
}

# Locate the changes directory of the active methodology.
# Prints the path or nothing.
changes_dir() {
  root=$1
  if [ -d "$root/openspec/changes" ]; then echo "$root/openspec/changes"
  elif [ -d "$root/specs" ]; then echo "$root/specs"
  fi
}

# Read conventions.changes.types from .groma/config.yaml as "x:label" words.
# Falls back to DEFAULT_TYPES.
config_types() {
  cfg="$1/.groma/config.yaml"
  if [ -f "$cfg" ]; then
    t=$(awk '
      function indent(s) { match(s, /^ */); return RLENGTH }
      /^[ ]*#/ || /^[ ]*$/ { next }
      {
        i = indent($0); line = $0; sub(/^ */, "", line)
        if (intypes && i <= tindent) intypes = 0
        if (inchanges && i <= cindent) inchanges = 0
        if (inconv && i <= vindent) inconv = 0
        if (line ~ /^conventions:/) { inconv = 1; vindent = i; next }
        if (inconv && line ~ /^changes:/) { inchanges = 1; cindent = i; next }
        if (inchanges && line ~ /^types:/) { intypes = 1; tindent = i; next }
        if (intypes && line ~ /^[a-z]+:/) {
          k = line; sub(/:.*/, "", k); v = line; sub(/^[a-z]+:[ ]*/, "", v); gsub(/["\047]/, "", v)
          printf "%s:%s ", k, v
        }
      }' "$cfg")
    if [ -n "$t" ]; then echo "$t"; return; fi
  fi
  echo "$DEFAULT_TYPES"
}

# Is the name listed in .groma/conventions-baseline.txt below the global $ROOT?
# The baseline holds the changes that existed before the current naming rule.
in_baseline() { # name
  [ -f "$ROOT/.groma/conventions-baseline.txt" ] && grep -qxF -- "$1" "$ROOT/.groma/conventions-baseline.txt"
}

# The part of a name m<digits>-<rest> after the dash; nothing for other names.
after_milestone() { # name
  am=${1#m}
  [ "$am" != "$1" ] || return 0
  am_num=${am%%[!0-9]*}
  [ -n "$am_num" ] || return 0
  am=${am#"$am_num"}
  case "$am" in -?*) echo "${am#-}" ;; esac
}

# Milestone number of a name m<N>-<slug>, without leading zeros; nothing for other names.
milestone_of() { # name
  [ -n "$(after_milestone "$1")" ] || return 0
  mo=${1#m}; mo=${mo%%-*}
  mo=${mo#"${mo%%[!0]*}"}
  echo "${mo:-0}"
}

# Old umbrella milestone: a change that is itself the milestone (m003-v0-3). It is
# an m name from the baseline, or one with a zero-padded number, which the current
# format never has. Every other m<N>-<slug> is a change that belongs to milestone N.
is_umbrella() { # name
  [ -n "$(after_milestone "$1")" ] || return 1
  case "$1" in m0*) return 0 ;; esac
  in_baseline "$1"
}

# Type word of a milestone member: spike, fix or refactor; nothing for a plain
# change, an umbrella milestone and names outside a milestone.
type_word() { # name
  if is_umbrella "$1"; then return 0; fi
  case "$(after_milestone "$1")" in
    spike-?*) echo spike ;;
    fix-?*) echo fix ;;
    refactor-?*) echo refactor ;;
  esac
}

# Type letter of a change: the type word inside a milestone (m3-fix-x is f, m3-x
# is c), m only for an old umbrella milestone, else the letters before the number.
change_type() { # name
  if is_umbrella "$1"; then echo m; return 0; fi
  case "$(type_word "$1")" in
    spike) echo s; return 0 ;;
    fix) echo f; return 0 ;;
    refactor) echo r; return 0 ;;
  esac
  if [ -n "$(after_milestone "$1")" ]; then echo c; return 0; fi
  echo "${1%%[0-9]*}"
}

is_spike() { [ "$(change_type "$1")" = s ]; }

# Short id of a change for one-line output: the full name for a milestone member
# (m3 alone would name the milestone), else <type><N>.
short_id() { # name
  if [ -n "$(after_milestone "$1")" ] && ! is_umbrella "$1"; then echo "$1"; else echo "${1%%-*}"; fi
}

# List change names (one per line): active and archived, archive date prefix stripped.
# Each line: <name><TAB><location: active|archive><TAB><path>
list_changes() {
  dir=$1
  if [ -z "$dir" ] || [ ! -d "$dir" ]; then return 0; fi
  for p in "$dir"/*/; do
    [ -d "$p" ] || continue
    p=${p%/}; n=${p##*/}
    [ "$n" = "archive" ] && continue
    printf '%s\tactive\t%s\n' "$n" "$p"
  done
  if [ -d "$dir/archive" ]; then
    for p in "$dir/archive"/*/; do
      [ -d "$p" ] || continue
      p=${p%/}; n=${p##*/}
      n=$(echo "$n" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//')
      printf '%s\tarchive\t%s\n' "$n" "$p"
    done
  fi
}

# Escape a one-line string for use inside a JSON string: backslash and double
# quote escaped, other control characters (tabs) become spaces.
json_escape() {
  printf '%s' "$1" | tr '\001-\037' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g'
}
