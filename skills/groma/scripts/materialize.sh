#!/bin/sh
# Copy the groma skills into a project's agent skill folders, with the rules of
# `groma init` and `groma update` (cli/skills.js): a file is groma's to replace
# only when .groma/generated.json lists it and its hash still matches.
#
# Usage: materialize.sh [--update] [--dry-run] [--force] [--allow-downgrade] [--agents <a,b>] [--skills <s,t>] <project>
#   --agents   agents from agents.yaml whose skill folder gets the copies.
#              Required, except with --update: then the default is `agents`
#              minus `agents_via_plugin` from <project>/.groma/config.yaml
#   --update   refresh mode for an initialized project (same rules, see below);
#              does nothing when the config says `steps.skills_copy: skipped`
#              and no .groma/generated.json exists (the user declined the copy)
#   --dry-run  print the plan, write nothing
#   --force    also replace generated files the user edited
#   --allow-downgrade  go on when the project's copies come from a newer groma
#              (they are replaced by this, older version)
#   --skills   copy only these skill folders (default: every groma skill
#              folder installed next to this script's skill)
#
# Source: the folders `groma` and `groma-*` with a SKILL.md next to this
# script's skill folder; version from ../VERSION, skill folders per agent from
# ../agents.yaml, retired skills from ../retired-skills.txt. Needs `sha256sum`
# or `shasum`. The source must be groma itself, not a copy groma made: a
# source whose SKILL.md carries `generatedBy` is refused (exit 1), and so is
# groma's own repository as the project. An agent skills folder of the project
# that is the source folder itself is skipped with a note.
#
# Writes only below <agent skills_dir>/groma*/ and .groma/generated.json:
#   - missing file: created
#   - recorded file whose hash still matches the record: replaced
#   - recorded file the user edited: kept and reported (unless --force)
#   - existing file or skill folder without a record: conflict, left untouched
#   - a symbolic link at or above a path, or a skills folder that leads out of
#     the project: conflict, never written into, never deleted from
#   - recorded file that a copied skill no longer has, or of a skill listed in
#     retired-skills.txt (and in --skills, when given): deleted when unchanged,
#     kept and reported when edited
#   - recorded file of any other skill (absent from a smaller or older source):
#     kept with its record
# Copied SKILL.md files get `metadata.generatedBy: groma@<version>`.
# Never runs `claude plugin disable` and never edits settings.
#
# Output (tab-separated), one line per file that needs attention:
#   create|update|remove|edited|conflict<TAB><path>
#   note<TAB><text>
#   plugin<TAB>claude<TAB><command>   the groma Claude plugin is also active:
#                                     the command switches it off for this project
#   summary<TAB>created=N<TAB>updated=N<TAB>removed=N<TAB>edited=N<TAB>conflicts=N<TAB>agents=a,b<TAB>version=X<TAB>dry_run=0|1
# Exit codes: 0 ok, 1 failure or refusal (nothing written unless a write itself
# failed; then generated.json records what was written), 2 usage error.
#
# Environment: GROMA_PLUGIN_CHECK_TIMEOUT, seconds to wait for
# `claude plugin list` (default 10).
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
SRC=$(CDPATH='' cd -- "$HERE/../.." && pwd -P)
AGENTS_YAML="$HERE/../agents.yaml"
VERSION_FILE="$HERE/../VERSION"
RETIRED_FILE="$HERE/../retired-skills.txt"
GENERATED=.groma/generated.json
CONFIG=.groma/config.yaml
DISABLE_CMD="claude plugin disable groma@groma --scope local"

usage() { echo "usage: materialize.sh [--update] [--dry-run] [--force] [--allow-downgrade] [--agents <a,b>] [--skills <s,t>] <project>" >&2; exit 2; }

UPDATE=0 DRY=0 FORCE=0 DOWNGRADE=0 AGENTS="" ONLY="" PROJECT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --update) UPDATE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --force) FORCE=1; shift ;;
    --allow-downgrade) DOWNGRADE=1; shift ;;
    --agents) [ $# -ge 2 ] || usage; AGENTS=$2; shift 2 ;;
    --skills) [ $# -ge 2 ] || usage; ONLY=$2; shift 2 ;;
    -*) echo "unknown option: $1" >&2; usage ;;
    *) [ -z "$PROJECT" ] || usage; PROJECT=$1; shift ;;
  esac
done
[ -n "$PROJECT" ] || usage
[ -d "$PROJECT" ] || { echo "project not found: $PROJECT" >&2; exit 2; }
PROJECT=$(CDPATH='' cd -- "$PROJECT" && pwd -P)
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
VERSION=$(tr -d ' \t\r\n' < "$VERSION_FILE")
TAG="groma@$VERSION"

summary() { # created updated removed edited conflicts
  printf 'summary\tcreated=%d\tupdated=%d\tremoved=%d\tedited=%d\tconflicts=%d\tagents=%s\tversion=%s\tdry_run=%d\n' "$1" "$2" "$3" "$4" "$5" "$AGENTS" "$VERSION" "$DRY"
}

# 0 when both paths are the same folder (links and spellings resolved)
same_file() { # a b
  [ -d "$1" ] && [ -d "$2" ] || return 1
  # shellcheck disable=SC2012
  [ "$(ls -di "$1/." 2>/dev/null | awk '{ print $1 }')" = "$(ls -di "$2/." 2>/dev/null | awk '{ print $1 }')" ] || return 1
  [ "$(df -P "$1" | awk 'NR == 2 { print $1 }')" = "$(df -P "$2" | awk 'NR == 2 { print $1 }')" ]
}

# The source must be groma itself. Copies that groma made carry generatedBy in
# their SKILL.md, wherever they lie and however their path is spelled; they
# hold the user's edits and files, which must not spread as groma content.
if [ -f "$HERE/../SKILL.md" ] && LC_ALL=C awk '
    NR == 1 { if ($0 != "---") exit 1; next }
    /^---/ && NR > 2 { exit 1 }
    /^[ \t]+generatedBy:/ { found = 1; exit 0 }
    END { exit !found }' "$HERE/../SKILL.md"; then
  echo "the groma skills at $SRC are a copy that groma made for a project (their SKILL.md carries generatedBy): copies cannot refresh themselves or serve as a source." >&2
  echo "Use groma itself instead: the Claude plugin (claude plugin update groma), npx skills add Zeotyn/groma --all, or the CLI (npx groma-cli update)." >&2
  exit 1
fi
if same_file "$SRC" "$PROJECT/skills"; then
  echo "$PROJECT is groma's source repository (its skills/ folder is the source of this run): nothing to copy here." >&2
  exit 1
fi

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

# The user declined the project copy and none exists: an update makes none.
if [ "$UPDATE" -eq 1 ] && [ -f "$PROJECT/$CONFIG" ] && [ ! -e "$PROJECT/$GENERATED" ]; then
  state=$(awk '
    /^[^ \t#]/ { steps = ($0 ~ /^steps:/) }
    steps && match($0, /(^  |[{,][ \t]*)skills_copy:[ \t]*["\047]?[a-z]+/) {
      v = substr($0, RSTART, RLENGTH); sub(/.*skills_copy:[ \t]*["\047]?/, "", v); print v; exit
    }' "$PROJECT/$CONFIG")
  if [ "$state" = skipped ]; then
    printf 'note\tsteps.skills_copy is skipped: the copy was declined, nothing to refresh\n'
    summary 0 0 0 0 0
    exit 0
  fi
fi

# No downgrade: copies of a newer groma are not replaced by older ones.
# A pre-release (1.2.3-rc.1) is older than its release (1.2.3).
OLD_TAG=""
if [ -s "$PROJECT/$GENERATED" ]; then
  OLD_TAG=$(sed -n 's/.*"generatedBy"[[:space:]]*:[[:space:]]*"\(groma@[^"]*\)".*/\1/p' "$PROJECT/$GENERATED" | head -n 1)
fi
if [ -n "$OLD_TAG" ] && [ "$DOWNGRADE" -eq 0 ] && awk -v a="${OLD_TAG#groma@}" -v b="$VERSION" 'BEGIN {
    pa = a; pb = b
    if (sub(/^[^-]*-/, "", pa) == 0) pa = ""
    if (sub(/^[^-]*-/, "", pb) == 0) pb = ""
    sub(/-.*/, "", a); sub(/-.*/, "", b)
    split(a, x, "."); split(b, y, ".")
    for (i = 1; i <= 3; i++) { if (x[i] + 0 > y[i] + 0) exit 0; if (x[i] + 0 < y[i] + 0) exit 1 }
    if (pa == pb) exit 1
    if (pa == "" || pb == "") exit (pa == "" ? 0 : 1)
    exit (pa > pb ? 0 : 1) }'; then
  echo "$GENERATED was written by $OLD_TAG, which is newer than this groma ($VERSION): update groma first. Only to go back to $VERSION on purpose, pass --allow-downgrade" >&2
  exit 1
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

# Where <rel> (or its deepest existing ancestor) really is; empty when that is
# not a folder inside the project.
real_inside() { # rel
  p=$1
  while [ ! -e "$PROJECT/$p" ] && [ ! -L "$PROJECT/$p" ]; do
    case "$p" in */*) p=${p%/*} ;; *) printf '%s\n' "$PROJECT"; return 0 ;; esac
  done
  [ -d "$PROJECT/$p" ] || return 0
  real=$(CDPATH='' cd -- "$PROJECT/$p" 2>/dev/null && pwd -P) || return 0
  case "$real/" in "$PROJECT"/*) printf '%s\n' "$real" ;; esac
}

: > "$WORK/dirs"
: > "$WORK/blocked"
: > "$WORK/source-dirs"
has_claude=0
for a in $(printf '%s' "$AGENTS" | tr ',' ' '); do
  d=$(awk -F "$TAB" -v a="$a" '$1 == a { print $2; exit }' "$WORK/agent-table")
  [ -n "$d" ] || { echo "unknown agent: $a (known: $(cut -f1 "$WORK/agent-table" | tr '\n' ' ' | sed 's/ $//'))" >&2; exit 2; }
  [ "$a" != claude ] || has_claude=1
  if grep -qxF "$d" "$WORK/dirs" "$WORK/blocked" "$WORK/source-dirs"; then continue; fi
  if [ -z "$(real_inside "$d")" ]; then
    # a symbolic link leads out of the project: never write there
    printf '%s\n' "$d" >> "$WORK/blocked"
    continue
  fi
  if same_file "$SRC" "$PROJECT/$d"; then
    # this folder is the source of the run: nothing to copy onto itself
    printf '%s\n' "$d" >> "$WORK/source-dirs"
    continue
  fi
  printf '%s\n' "$d" >> "$WORK/dirs"
done

# --- source: staged copies with generatedBy ----------------------------------
# Mirrors addGeneratedBy byte for byte: the line replaces an existing
# `  generatedBy:` line of the frontmatter, else goes below the first
# `metadata:` key, else a new `metadata:` block goes before the closing `---`. A file that does not start with the bytes `---\n` (a BOM,
# CRLF, no frontmatter) is copied unchanged.
add_generated_by() { # file tag
  if [ "$(head -c 4 "$1" | od -An -tx1 | tr -d ' \n')" != 2d2d2d0a ]; then cat "$1"; return 0; fi
  if [ "$(tail -c 1 "$1" | od -An -tx1 | tr -d ' \n')" = 0a ]; then eof=1; else eof=0; fi
  LC_ALL=C awk -v tag="$2" -v eof="$eof" '
    function put(s) { printf "%s%s", (out++ ? "\n" : ""), s }
    { line[NR] = $0 }
    END {
      n = NR; close_at = 0; meta = 0; old = 0
      for (i = 3; i <= n; i++) if (substr(line[i], 1, 3) == "---") { close_at = i; break }
      # the closing line must be followed by a line break only when it is the
      # last line; the metadata key needs its line break inside the head
      if (close_at) for (i = 1; i < close_at; i++) if (line[i] ~ /^  generatedBy:/) { old = i; break }
      if (close_at && !old) for (i = 2; i < close_at; i++) if (line[i] ~ /^metadata:[ \t]*$/) { meta = i; break }
      out = 0
      for (i = 1; i <= n; i++) {
        if (i == old) { put("  generatedBy: " tag); continue }
        if (close_at && !old && !meta && i == close_at) { put("metadata:"); put("  generatedBy: " tag) }
        put(line[i])
        if (meta && i == meta) put("  generatedBy: " tag)
      }
      if (eof) printf "\n"
    }
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

# Fail before anything is written when a source file cannot be copied by name.
bad=$(cd "$STAGE" && find . -type f \( -name "*$TAB*" -o -name '*\\*' \) | head -n 1)
[ -z "$bad" ] || { echo "unsupported file name in the source (tab or backslash): ${bad#./}" >&2; exit 1; }
[ "$(wc -l < "$WORK/src" | tr -d ' ')" -eq "$(cd "$STAGE" && find . -type f | wc -l | tr -d ' ')" ] \
  || { echo "unsupported file name in the source (line break), or a file could not be read" >&2; exit 1; }
while IFS="$TAB" read -r _ rel; do
  [ -f "$STAGE/$rel" ] || { echo "unsupported file name in the source: $rel" >&2; exit 1; }
done < "$WORK/src"

# retired skills, limited to the --skills selection
: > "$WORK/retired"
if [ -f "$RETIRED_FILE" ]; then
  sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "$RETIRED_FILE" | while IFS= read -r name; do
    if [ -n "$ONLY" ]; then
      case ",$ONLY," in *",$name,"*) ;; *) continue ;; esac
    fi
    printf '%s\n' "$name"
  done > "$WORK/retired"
fi

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
# The skills folder itself may be a link to a folder inside the project
# (`find -H`); links below it are listed and never followed.
: > "$WORK/current"
: > "$WORK/existing-dirs"
: > "$WORK/links"
while IFS= read -r d; do
  [ -d "$PROJECT/$d" ] || continue
  (cd "$PROJECT" && hash_files -H "$d" -path "$d/groma*" | awk -F "$TAB" '{ printf "%s\t%s\n", $2, $1 }') >> "$WORK/current"
  (cd "$PROJECT" && find -H "$d" -path "$d/groma*" -type l) >> "$WORK/links"
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
  FILENAME == ARGV[2] { skills[++ns] = $1; gone[$1] = 1; next }
  FILENAME == ARGV[3] { s = $2; sub(/\/.*/, "", s); nf[s]++; file[s, nf[s]] = substr($2, length(s) + 2); srch[$2] = $1; next }
  FILENAME == ARGV[4] { if (!($1 in known)) korder[++nk] = $1; known[$1] = $2; next }
  FILENAME == ARGV[5] { if (!($1 in cur)) cur[$1] = $2; next }
  FILENAME == ARGV[6] { exdir[$1] = 1; next }
  FILENAME == ARGV[7] { link[$1] = 1; next }
  FILENAME == ARGV[8] { gone[$1] = 1; next }
  FILENAME == ARGV[9] { blocked[++nb] = $1; next }
  function out(action, path, hash, src) { printf "%s\t%s\t%s\t%s\n", action, path, hash, src }
  # the symbolic link at or above <path>, or ""
  function linked(path,   n, seg, j, p) {
    n = split(path, seg, "/"); p = ""
    for (j = 1; j <= n; j++) { p = (j == 1 ? seg[1] : p "/" seg[j]); if (p in link) return p }
    return ""
  }
  # 1 when <path> lies in a groma* skill folder of a selected agent; sets skill
  function ours(path,   i, rest, n, seg, j) {
    n = split(path, seg, "/")
    for (j = 1; j <= n; j++) if (seg[j] == "..") return 0
    for (i = 1; i <= nd; i++) if (index(path, dirs[i] "/") == 1) {
      rest = substr(path, length(dirs[i]) + 2)
      if (rest ~ /^groma[^\/]*\/./) { skill = rest; sub(/\/.*/, "", skill); return 1 }
    }
    return 0
  }
  END {
    for (i = 1; i <= nb; i++) out("conflict", blocked[i], "", "")
    for (i = 1; i <= nd; i++) for (j = 1; j <= ns; j++) {
      dir = dirs[i] "/" skills[j]
      if ((dir in exdir) && !(dir in link)) {
        owned = 0
        for (k = 1; k <= nk; k++) if (index(korder[k], dir "/") == 1) { owned = 1; break }
        if (!owned) { out("conflict", dir, "", ""); continue }
      }
      for (f = 1; f <= nf[skills[j]]; f++) {
        src = skills[j] "/" file[skills[j], f]; path = dirs[i] "/" src; h = srch[src]
        l = linked(path)
        if (l != "") {
          if (!(l in said)) { out("conflict", l, "", ""); said[l] = 1 }
          if (path in known) { out("carry", path, known[path], ""); rec[path] = 1 }
        }
        else if (!(path in cur)) { out("create", path, h, src); rec[path] = 1 }
        else if (!(path in known)) out("conflict", path, "", "")
        else if (cur[path] == h) { out("same", path, h, src); rec[path] = 1 }
        else if (cur[path] != known[path] && !force) { out("edited", path, known[path], ""); rec[path] = 1 }
        else { out("update", path, h, src); rec[path] = 1 }
      }
    }
    # Recorded files that were not planned above. Deleted only when groma no
    # longer ships them: the skill is copied in this run (the file left the
    # skill) or is listed as retired. Everything else keeps its record.
    for (k = 1; k <= nk; k++) {
      path = korder[k]
      if (path in rec || !(path in cur)) continue
      if (!ours(path) || !(skill in gone) || linked(path) != "") out("carry", path, known[path], "")
      else if (cur[path] == known[path]) out("remove", path, known[path], "")
      else out("edited", path, known[path], "")
    }
  }
' "$WORK/dirs" "$WORK/skills" "$WORK/src" "$WORK/known" "$WORK/current" "$WORK/existing-dirs" "$WORK/links" "$WORK/retired" "$WORK/blocked" > "$WORK/plan"

# --- apply ---------------------------------------------------------------------
# generated.json from the plan. Writes that are not listed in <done> count as
# not made: a create has no record, an update or removal keeps its old record.
write_generated() { # done-file | "" (everything was written), generatedBy
  awk -F "$TAB" -v all="$([ -n "$1" ] && echo 0 || echo 1)" '
    FILENAME == ARGV[1] { done[$1] = 1; next }
    FILENAME == ARGV[2] { known[$1] = $2; next }
    $1 == "conflict" { next }
    $1 == "remove" { if (!all && !($2 in done)) printf "%s\t%s\n", $2, $3; next }
    $1 == "update" && !all && !($2 in done) { printf "%s\t%s\n", $2, known[$2]; next }
    { printf "%s\t%s\n", $2, $3 }
  ' "${1:-/dev/null}" "$WORK/known" "$WORK/plan" | LC_ALL=C sort -t "$TAB" -k 1,1 \
    | awk -F "$TAB" -v tag="$2" '
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
  mkdir -p "$PROJECT/.groma"
  cat "$WORK/generated.json" > "$PROJECT/$GENERATED"
}

# generated.json is written before the first file is touched: planned creates
# at their new hash, updates and removals at their old one, under the old
# generatedBy. A run that fails or is killed midway leaves every file it wrote
# recorded, so the next run owns it. Each file is copied beside its place and
# renamed, so no half-written file appears under its name.
if [ "$DRY" -eq 0 ]; then
  : > "$WORK/done"
  if grep -Eq "^(create|update|remove)$TAB" "$WORK/plan"; then
    write_generated "$WORK/done" "${OLD_TAG:-$TAG}"
  fi
  trap 'if [ -f "$WORK/applying" ]; then write_generated "$WORK/done" "${OLD_TAG:-$TAG}" || true; echo "stopped while writing: $GENERATED records the files written so far, run again after fixing the cause" >&2; fi; rm -rf "$WORK"' EXIT
  : > "$WORK/applying"
  while IFS="$TAB" read -r action path _ src; do
    [ -n "$path" ] || continue
    dst="${PROJECT:?}/${path:?}"
    case "$action" in
      create|update)
        tmp="$(dirname "$dst")/.groma-tmp-$(basename "$dst")"
        mkdir -p "$(dirname "$dst")"
        cp -p "$STAGE/$src" "$tmp"
        mv -f "$tmp" "$dst"
        ;;
      remove)
        unlink "$dst"
        # drop folders the removal left empty, up to the skill folder
        d=$(dirname "$path")
        while [ "$(printf '%s' "$d" | tr -cd '/' | wc -c)" -ge 2 ] && rmdir "$PROJECT/$d" 2>/dev/null; do
          d=$(dirname "$d")
        done
        ;;
      *) continue ;;
    esac
    printf '%s\n' "$path" >> "$WORK/done"
  done < "$WORK/plan"
  write_generated "" "$TAG"
  unlink "$WORK/applying"
fi

# --- report --------------------------------------------------------------------
while IFS= read -r d; do
  printf 'note\t%s is the source folder of this run, nothing is copied onto it\n' "$d"
done < "$WORK/source-dirs"
awk -F "$TAB" '$1 != "same" && $1 != "carry" { printf "%s\t%s\n", $1, $2 }' "$WORK/plan"

# The groma Claude plugin and a project copy list every skill twice (ADR 0050).
# Claude Code keeps plugins in <config dir>/plugins/cache/ and marketplaces in
# <config dir>/plugins/marketplaces/; a script that runs from there proves the
# plugin without a call. Otherwise ask claude, without stdin and with a limit.
plugin_active() {
  case "$HERE" in */plugins/cache/*/skills/groma/scripts|*/plugins/marketplaces/*/skills/groma/scripts) return 0 ;; esac
  command -v claude >/dev/null 2>&1 || return 1
  limit=${GROMA_PLUGIN_CHECK_TIMEOUT:-10}
  claude plugin list < /dev/null > "$WORK/plugins" 2>/dev/null &
  pid=$!
  ( sleep "$limit"; kill "$pid" 2>/dev/null ) < /dev/null > /dev/null 2>&1 &
  watchdog=$!
  wait "$pid" 2>/dev/null || true
  kill "$watchdog" 2>/dev/null || true
  grep -Eq '(^|[[:space:]])groma@' "$WORK/plugins"
}
if [ "$has_claude" -eq 1 ] && plugin_active; then
  printf 'plugin\tclaude\t%s\n' "$DISABLE_CMD"
fi

# shellcheck disable=SC2046
summary $(awk -F "$TAB" '{ n[$1]++ } END { print n["create"] + 0, n["update"] + 0, n["remove"] + 0, n["edited"] + 0, n["conflict"] + 0 }' "$WORK/plan")
