#!/bin/sh
# Shared helpers for the change-convention scripts. Source, do not execute.
# shellcheck shell=sh

DEFAULT_TYPES="m:milestone c:change f:fix s:spike r:refactor d:docs"

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

config_digits() {
  cfg="$1/.groma/config.yaml"
  d=""
  [ -f "$cfg" ] && d=$(awk '/^[ ]+digits:[ ]*[0-9]+/ { sub(/.*digits:[ ]*/, ""); print; exit }' "$cfg")
  echo "${d:-3}"
}

# List change names (one per line): active and archived, archive date prefix stripped.
# Each line: <name><TAB><location: active|archive><TAB><path>
list_changes() {
  dir=$1
  [ -n "$dir" ] && [ -d "$dir" ] || return 0
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
