#!/bin/sh
# Copy the groma skills into a project's agent skill folders, with the rules of
# `groma init` and `groma update` (cli/skills.js): a file is groma's to replace
# only when .groma/generated.json lists it and its hash still matches.
#
# Usage: materialize.sh [--update] [--dry-run] [--force] [--agents <a,b>] [--skills <s,t>] <project>
#   --agents   agents from agents.yaml whose skill folder gets the copies.
#              Required, except with --update: then the default is `agents`
#              minus `agents_via_plugin` from <project>/.groma/config.yaml
#   --update   refresh mode for an initialized project (same rules, see above)
#   --dry-run  print the plan, write nothing
#   --force    also replace generated files the user edited
#   --skills   copy only these skill folders (default: every groma skill
#              folder installed next to this script's skill)
#
# Source: the folders `groma` and `groma-*` with a SKILL.md next to this
# script's skill folder; version from ../VERSION, skill folders per agent from
# ../agents.yaml. Needs `sha256sum` or `shasum`.
#
# Writes only below <agent skills_dir>/groma*/ and .groma/generated.json:
#   - missing file: created
#   - recorded file whose hash still matches the record: replaced
#   - recorded file the user edited: kept and reported (unless --force)
#   - existing file or skill folder without a record: conflict, left untouched
#   - recorded file of a skill that is no longer shipped: deleted when
#     unchanged, kept and reported when edited
# Copied SKILL.md files get `metadata.generatedBy: groma@<version>`.
# Never runs `claude plugin disable` and never edits settings.
#
# Output (tab-separated), one line per file that needs attention:
#   create|update|remove|edited|conflict<TAB><path>
#   plugin<TAB>claude<TAB><command>   the groma Claude plugin is also active:
#                                     the command switches it off for this project
#   summary<TAB>created=N<TAB>updated=N<TAB>removed=N<TAB>edited=N<TAB>conflicts=N<TAB>agents=a,b<TAB>version=X<TAB>dry_run=0|1
# Exit codes: 0 ok, 1 failure, 2 usage error.
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
SRC=$(CDPATH='' cd -- "$HERE/../.." && pwd)
AGENTS_YAML="$HERE/../agents.yaml"
VERSION_FILE="$HERE/../VERSION"
GENERATED=.groma/generated.json
CONFIG=.groma/config.yaml
DISABLE_CMD="claude plugin disable groma@groma --scope local"

usage() { echo "usage: materialize.sh [--update] [--dry-run] [--force] [--agents <a,b>] [--skills <s,t>] <project>" >&2; exit 2; }

UPDATE=0 DRY=0 FORCE=0 AGENTS="" ONLY="" PROJECT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --update) UPDATE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --force) FORCE=1; shift ;;
    --agents) [ $# -ge 2 ] || usage; AGENTS=$2; shift 2 ;;
    --skills) [ $# -ge 2 ] || usage; ONLY=$2; shift 2 ;;
    -*) echo "unknown option: $1" >&2; usage ;;
    *) [ -z "$PROJECT" ] || usage; PROJECT=$1; shift ;;
  esac
done
[ -n "$PROJECT" ] || usage
[ -d "$PROJECT" ] || { echo "project not found: $PROJECT" >&2; exit 2; }
PROJECT=$(CDPATH='' cd -- "$PROJECT" && pwd)
[ -f "$AGENTS_YAML" ] || { echo "agents.yaml not found next to the script: $AGENTS_YAML" >&2; exit 1; }
[ -f "$VERSION_FILE" ] || { echo "VERSION not found next to the script: $VERSION_FILE" >&2; exit 1; }

if command -v sha256sum >/dev/null 2>&1; then
  sha() { sha256sum "$@"; }
elif command -v shasum >/dev/null 2>&1; then
  sha() { shasum -a 256 "$@"; }
else
  echo "sha256sum or shasum is required" >&2; exit 1
fi

TAB=$(printf '\t')
TAG="groma@$(tr -d ' \t\r\n' < "$VERSION_FILE")"

# --- agents ------------------------------------------------------------------
# A list value of the config, inline ([a, b]) or block (- a), one item per line.
config_list() { # key
  awk -v key="$1" '
    function emit(s,   n, i, a, x) {
      sub(/[ \t]+#.*$/, "", s); gsub(/[][]/, "", s)
      n = split(s, a, ",")
      for (i = 1; i <= n; i++) { x = a[i]; gsub(/^[ \t"\047]+|[ \t"\047]+$/, "", x); if (x != "") print x }
    }
    /^[^ \t#-]/ { open = 0 }
    index($0, key ":") == 1 { v = substr($0, length(key) + 2); if (v ~ /^[ \t]*(#.*)?$/) open = 1; else emit(v); next }
    open && /^[ \t]*-[ \t]/ { v = $0; sub(/^[ \t]*-[ \t]*/, "", v); emit(v) }
  ' "$PROJECT/$CONFIG"
}

if [ -z "$AGENTS" ]; then
  [ "$UPDATE" -eq 1 ] || { echo "--agents is required (or --update with $CONFIG)" >&2; exit 2; }
  [ -f "$PROJECT/$CONFIG" ] || { echo "$CONFIG not found: pass --agents" >&2; exit 2; }
  via=$(config_list agents_via_plugin | tr '\n' ' ')
  for a in $(config_list agents); do
    case " $via " in *" $a "*) continue ;; esac
    AGENTS="${AGENTS:+$AGENTS,}$a"
  done
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/groma-materialize.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
trap 'exit 1' HUP INT TERM

# agent<TAB>skills_dir for every agent in agents.yaml
awk '
  /^[^ \t#]/ { top = $0; sub(/:.*/, "", top); next }
  top != "agents" { next }
  /^  [A-Za-z0-9_-]+:[ \t]*(#.*)?$/ { a = $1; sub(/:.*/, "", a); next }
  /^    skills_dir:/ { v = $0; sub(/^    skills_dir:[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v); gsub(/^["\047]|["\047]$/, "", v); printf "%s\t%s\n", a, v }
' "$AGENTS_YAML" > "$WORK/agent-table"

: > "$WORK/dirs"
has_claude=0
for a in $(printf '%s' "$AGENTS" | tr ',' ' '); do
  d=$(awk -F "$TAB" -v a="$a" '$1 == a { print $2; exit }' "$WORK/agent-table")
  [ -n "$d" ] || { echo "unknown agent: $a (known: $(cut -f1 "$WORK/agent-table" | tr '\n' ' ' | sed 's/ $//'))" >&2; exit 2; }
  grep -qxF "$d" "$WORK/dirs" || printf '%s\n' "$d" >> "$WORK/dirs"
  [ "$a" != claude ] || has_claude=1
done

# --- source: staged copies with generatedBy ----------------------------------
# Mirrors addGeneratedBy: the line goes below an existing `metadata:` key of the
# frontmatter, or a new `metadata:` block goes before the closing `---`. A
# generatedBy line of an earlier copy (source is itself a project copy) is
# dropped first, so a copy of a copy carries one line.
add_generated_by() { # file tag
  if [ -s "$1" ] && [ "$(tail -c 1 "$1" | wc -l | tr -d ' ')" -eq 0 ]; then eof=0; else eof=1; fi
  awk -v tag="$2" -v eof="$eof" '
    { line[NR] = $0 }
    END {
      n = NR; close_at = 0; meta = 0
      if (line[1] == "---") for (i = 3; i <= n; i++) if (substr(line[i], 1, 3) == "---") { close_at = i; break }
      if (close_at) {
        for (i = 2; i < close_at; i++) if (line[i] ~ /^metadata:[ \t]*$/) { meta = i; break }
        if (meta && line[meta + 1] ~ /^  generatedBy: groma@/) drop = meta + 1
      }
      out = 0
      for (i = 1; i <= n; i++) {
        if (i == drop) continue
        if (close_at && !meta && i == close_at) { put("metadata:"); put("  generatedBy: " tag) }
        put(line[i])
        if (meta && i == meta) put("  generatedBy: " tag)
      }
      if (eof && n > 0) printf "\n"
    }
    function put(s) { printf "%s%s", (out++ ? "\n" : ""), s }
  ' "$1"
}

STAGE="$WORK/stage"
mkdir "$STAGE"
: > "$WORK/skills"
for dir in "$SRC"/groma "$SRC"/groma-*; do
  [ -f "$dir/SKILL.md" ] || continue
  name=$(basename "$dir")
  if [ -n "$ONLY" ]; then
    case ",$ONLY," in *",$name,"*) ;; *) continue ;; esac
  fi
  cp -Rp "$dir" "$STAGE/$name"
  add_generated_by "$dir/SKILL.md" "$TAG" > "$WORK/skill.md"
  cat "$WORK/skill.md" > "$STAGE/$name/SKILL.md"
  printf '%s\n' "$name" >> "$WORK/skills"
done
[ -s "$WORK/skills" ] || { echo "no groma skill folders found in $SRC" >&2; exit 1; }

# hash<TAB>path for every regular file below the given paths (relative to cwd)
hash_files() {
  find "$@" -type f -exec sh -c '
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi' sh {} + 2>/dev/null \
    | sed -e 's/^\\//' -e "s/^\([0-9a-f]\{64\}\) [ *]\(\.\/\)\{0,1\}/\1$TAB/"
}

(cd "$STAGE" && hash_files . | LC_ALL=C sort -t "$TAB" -k 2) > "$WORK/src"

# --- project state -------------------------------------------------------------
# path<TAB>hash from generated.json (pretty or compact JSON)
: > "$WORK/known"
if [ -s "$PROJECT/$GENERATED" ]; then
  grep -q '"files"' "$PROJECT/$GENERATED" || { echo "$GENERATED is not a groma generated file (no \"files\" key)" >&2; exit 1; }
  awk '
    { text = text $0 "\n" }
    END {
      re = "\"([^\"\\\\]|\\\\.)*\"[ \t\n]*:[ \t\n]*\"[0-9a-f]+\""
      while (match(text, re)) {
        pair = substr(text, RSTART, RLENGTH); text = substr(text, RSTART + RLENGTH)
        hash = pair; sub(/"$/, "", hash); sub(/.*"/, "", hash)
        if (length(hash) != 64) continue
        key = pair; sub(/"[ \t\n]*:[ \t\n]*"[0-9a-f]+"$/, "", key); key = substr(key, 2)
        gsub(/\\"/, "\"", key); gsub(/\\\//, "/", key); gsub(/\\\\/, "\\", key)
        if (key !~ /[\t\n]/) printf "%s\t%s\n", key, hash
      }
    }
  ' "$PROJECT/$GENERATED" > "$WORK/known"
fi

# path<TAB>hash for what exists in the project: every file in the selected
# agents' groma* skill folders, plus recorded paths elsewhere (existence only).
# A symbolic link counts as existing and never as unchanged.
: > "$WORK/current"
: > "$WORK/existing-dirs"
while IFS= read -r d; do
  [ -d "$PROJECT/$d" ] || continue
  (cd "$PROJECT" && hash_files "$d" -path "$d/groma*" | awk -F "$TAB" '{ printf "%s\t%s\n", $2, $1 }') >> "$WORK/current"
  (cd "$PROJECT" && find "$d" -path "$d/groma*" -type l | sed "s/\$/${TAB}symlink/") >> "$WORK/current"
  while IFS= read -r s; do
    if [ -e "$PROJECT/$d/$s" ] || [ -L "$PROJECT/$d/$s" ]; then printf '%s\n' "$d/$s" >> "$WORK/existing-dirs"; fi
  done < "$WORK/skills"
done < "$WORK/dirs"
while IFS="$TAB" read -r path _; do
  if [ -e "$PROJECT/$path" ] || [ -L "$PROJECT/$path" ]; then printf '%s\texists\n' "$path"; fi
done < "$WORK/known" >> "$WORK/current"

# --- plan ----------------------------------------------------------------------
# action<TAB>path<TAB>hash<TAB>source ; actions: create update same edited
# conflict remove carry. Lines with a hash become records of generated.json.
awk -F "$TAB" -v force="$FORCE" '
  FILENAME == ARGV[1] { dirs[++nd] = $1; next }
  FILENAME == ARGV[2] { skills[++ns] = $1; next }
  FILENAME == ARGV[3] { s = $2; sub(/\/.*/, "", s); nf[s]++; file[s, nf[s]] = substr($2, length(s) + 2); srch[$2] = $1; next }
  FILENAME == ARGV[4] { if (!($1 in known)) korder[++nk] = $1; known[$1] = $2; next }
  FILENAME == ARGV[5] { if (!($1 in cur)) cur[$1] = $2; next }
  FILENAME == ARGV[6] { exdir[$1] = 1; next }
  function out(action, path, hash, src) { printf "%s\t%s\t%s\t%s\n", action, path, hash, src }
  function ours(path,   i, rest, n, seg, j) {
    n = split(path, seg, "/")
    for (j = 1; j <= n; j++) if (seg[j] == "..") return 0
    for (i = 1; i <= nd; i++) if (index(path, dirs[i] "/") == 1) {
      rest = substr(path, length(dirs[i]) + 2)
      if (rest ~ /^groma[^\/]*\/./) return 1
    }
    return 0
  }
  END {
    for (i = 1; i <= nd; i++) for (j = 1; j <= ns; j++) {
      dir = dirs[i] "/" skills[j]
      if (dir in exdir) {
        owned = 0
        for (k = 1; k <= nk; k++) if (index(korder[k], dir "/") == 1) { owned = 1; break }
        if (!owned) { out("conflict", dir, "", ""); continue }
      }
      for (f = 1; f <= nf[skills[j]]; f++) {
        src = skills[j] "/" file[skills[j], f]; path = dirs[i] "/" src; h = srch[src]
        if (!(path in cur)) { out("create", path, h, src); rec[path] = 1 }
        else if (!(path in known)) out("conflict", path, "", "")
        else if (cur[path] == h) { out("same", path, h, src); rec[path] = 1 }
        else if (cur[path] != known[path] && !force) { out("edited", path, known[path], ""); rec[path] = 1 }
        else { out("update", path, h, src); rec[path] = 1 }
      }
    }
    for (k = 1; k <= nk; k++) {
      path = korder[k]
      if (path in rec || !(path in cur)) continue
      if (!ours(path)) out("carry", path, known[path], "")
      else if (cur[path] == known[path]) out("remove", path, "", "")
      else out("edited", path, known[path], "")
    }
  }
' "$WORK/dirs" "$WORK/skills" "$WORK/src" "$WORK/known" "$WORK/current" "$WORK/existing-dirs" > "$WORK/plan"

# --- apply ---------------------------------------------------------------------
if [ "$DRY" -eq 0 ]; then
  while IFS="$TAB" read -r action path _ src; do
    case "$action" in
      create|update)
        mkdir -p "$(dirname "$PROJECT/$path")"
        rm -f "$PROJECT/$path"
        cp -p "$STAGE/$src" "$PROJECT/$path"
        ;;
      remove)
        rm -f "$PROJECT/$path"
        # drop folders the removal left empty, up to the skill folder
        d=$(dirname "$path")
        while [ "$(printf '%s' "$d" | tr -cd '/' | wc -c)" -ge 2 ] && rmdir "$PROJECT/$d" 2>/dev/null; do
          d=$(dirname "$d")
        done
        ;;
    esac
  done < "$WORK/plan"

  mkdir -p "$PROJECT/.groma"
  awk -F "$TAB" '$3 != "" { printf "%s\t%s\n", $2, $3 }' "$WORK/plan" | LC_ALL=C sort -t "$TAB" -k 1,1 \
    | awk -F "$TAB" -v tag="$TAG" '
      function esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return s }
      { path[NR] = $1; hash[NR] = $2 }
      END {
        printf "{\n  \"generatedBy\": \"%s\",\n", tag
        if (NR == 0) printf "  \"files\": {}\n"
        else {
          printf "  \"files\": {\n"
          for (i = 1; i <= NR; i++) printf "    \"%s\": \"%s\"%s\n", esc(path[i]), hash[i], (i < NR ? "," : "")
          printf "  }\n"
        }
        printf "}\n"
      }' > "$WORK/generated.json"
  cat "$WORK/generated.json" > "$PROJECT/$GENERATED"
fi

# --- report --------------------------------------------------------------------
awk -F "$TAB" '$1 != "same" && $1 != "carry" { printf "%s\t%s\n", $1, $2 }' "$WORK/plan"

# The groma Claude plugin and a project copy list every skill twice (ADR 0050).
plugin_active() {
  case "$HERE" in */plugins/*) return 0 ;; esac
  command -v claude >/dev/null 2>&1 || return 1
  claude plugin list 2>/dev/null | grep -Eq '(^|[[:space:]])groma@'
}
if [ "$has_claude" -eq 1 ] && plugin_active; then
  printf 'plugin\tclaude\t%s\n' "$DISABLE_CMD"
fi

awk -F "$TAB" -v agents="$AGENTS" -v version="${TAG#groma@}" -v dry="$DRY" '
  { n[$1]++ }
  END { printf "summary\tcreated=%d\tupdated=%d\tremoved=%d\tedited=%d\tconflicts=%d\tagents=%s\tversion=%s\tdry_run=%d\n", n["create"], n["update"], n["remove"], n["edited"], n["conflict"], agents, version, dry }
' "$WORK/plan"
