#!/bin/sh
# Static code-style report. Read-only, runs no project tool.
#
# Usage: style-drift.sh [--table <code-style-tools.md>] [<project>]
#
# (a) tool: a style tool whose config pattern from the reference table matches
#     a file at the project root (`file#text`: the file contains text).
# (b) drift: tracked text files that disagree with the root `.editorconfig`
#     on indent_style, end_of_line, insert_final_newline or
#     trim_trailing_whitespace. Sections are applied in file order, the last
#     matching section wins. indent_style=space flags lines starting with a
#     tab, indent_style=tab lines starting with two or more spaces. Nested
#     .editorconfig files are not read.
# (c) unchecked: a tool with a check command whose name or first two command
#     words appear in none of the places listed in the table's "Where checks
#     run" section (CI workflows, package.json scripts, Makefile, ...).
#
# Output, tab-separated:
#   note<TAB><text>
#   tool<TAB><tool><TAB><config path><TAB><check command>
#   drift<TAB><property><TAB><file count><TAB><up to five paths, space-separated>
#   unchecked<TAB><tool><TAB><config path>
#   summary<TAB>tools=<n><TAB>drift=<n><TAB>unchecked=<n>
# Exit 0; usage errors exit 2.
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TABLE="$HERE/../../groma-lay-out/references/code-style-tools.md"
DIR=.
while [ $# -gt 0 ]; do
  case "$1" in
    --table) TABLE=$2; shift 2 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) DIR=$1; shift ;;
  esac
done
[ -d "$DIR" ] || { echo "not a directory: $DIR" >&2; exit 2; }
cd "$DIR"
TAB=$(printf '\t')
NL='
'
WORK=$(mktemp -d "${TMPDIR:-/tmp}/style-drift.XXXXXX")
trap 'rm -rf "$WORK"' EXIT INT TERM

tools=0 drift=0 unchecked=0

# --- (a) tools from the reference table ------------------------------------------

# rows of the first table as: id<TAB>tool<TAB>patterns<TAB>check
table_rows() {
  awk -F'|' '
    /^\| *Stack *\|/ { intable = 1; next }
    intable && /^\|/ {
      if ($2 ~ /^ *:?-+:? *$/) next
      tool = $3; pat = $5; check = $6
      gsub(/^ +| +$/, "", tool); gsub(/^ +| +$/, "", pat); gsub(/^ +| +$/, "", check)
      gsub(/`/, "", pat); gsub(/`/, "", check)
      id = tolower(tool); gsub(/ /, "-", id)
      if (tool != "") printf "%s\t%s\t%s\t%s\n", id, tool, pat, check
      next
    }
    intable && !/^\|/ { intable = 0 }' "$TABLE"
}

# rows of the "Where checks run" table as: kind<TAB>pattern
location_rows() {
  awk -F'|' '
    /^\| *Kind *\|/ { intable = 1; next }
    intable && /^\|/ {
      if ($2 ~ /^ *:?-+:? *$/) next
      kind = $2; pat = $3
      gsub(/^ +| +$/, "", kind); gsub(/^ +| +$/, "", pat); gsub(/`/, "", pat)
      if (kind != "") printf "%s\t%s\n", kind, pat
      next
    }
    intable && !/^\|/ { intable = 0 }' "$TABLE"
}

# first existing file for a comma-separated pattern list, honoring file#text
find_config() {
  oldifs=$IFS; IFS=','
  for pat in $1; do
    IFS=$oldifs
    pat=${pat# }; pat=${pat% }
    text=""
    case "$pat" in *'#'*) text=${pat#*#}; pat=${pat%%#*} ;; esac
    for f in $pat; do
      [ -f "$f" ] || continue
      if [ -z "$text" ] || grep -qF -- "$text" "$f" 2>/dev/null; then
        printf '%s\n' "$f"; IFS=$oldifs; return 0
      fi
    done
    IFS=','
  done
  IFS=$oldifs
  return 1
}

# the `scripts` object of a package.json
package_scripts() {
  awk '
    !found && index($0, "\"scripts\"") { found = 1; s = substr($0, index($0, "\"scripts\"")) ; $0 = s }
    found {
      n = split($0, ch, "")
      for (i = 1; i <= n; i++) {
        if (ch[i] == "{") depth++
        else if (ch[i] == "}") { depth--; if (depth == 0) { print; exit } }
      }
      print
    }' "$1"
}

# needle appears in any check location
mentioned() { # tool-id check-command
  w=$2
  for p in "npx --yes " "npx " "uvx " "uv run " "bundle exec " "pnpm exec " "poetry run "; do
    case "$w" in "$p"*) w=${w#"$p"} ;; esac
  done
  words=$(printf '%s' "$w" | awk '{ print ($2 == "" ? $1 : $1 " " $2) }')
  while IFS="$TAB" read -r kind pat; do
    [ -n "$kind" ] || continue
    for f in $pat; do
      [ -f "$f" ] || continue
      case "$kind" in
        package-scripts) content=$(package_scripts "$f") ;;
        *) content=$(cat "$f") ;;
      esac
      printf '%s\n' "$content" | grep -qiF -- "$1" && return 0
      [ -n "$words" ] && printf '%s\n' "$content" | grep -qiF -- "$words" && return 0
    done
  done <<EOF
$(location_rows)
EOF
  return 1
}

FOUND=""
if [ -f "$TABLE" ]; then
  # shellcheck disable=SC2034 # tool: display name, the id is used
  while IFS="$TAB" read -r id tool pat check; do
    [ -n "$id" ] || continue
    cfg=$(find_config "$pat") || continue
    tools=$((tools + 1))
    printf 'tool%s%s%s%s%s%s\n' "$TAB" "$id" "$TAB" "$cfg" "$TAB" "$check"
    [ -n "$check" ] && FOUND="$FOUND$id$TAB$cfg$TAB$check$NL"
  done <<EOF
$(table_rows)
EOF
else
  printf 'note%sstyle tools not detected (groma-lay-out missing)\n' "$TAB"
fi

# --- (b) editorconfig drift --------------------------------------------------------

if [ -f .editorconfig ]; then
  # rules: regex<TAB>property<TAB>value, in file order
  awk '
    function glob2re(g,   i, c, re, n, anchored) {
      anchored = index(g, "/") > 0
      sub(/^\//, "", g)
      re = ""; n = length(g)
      for (i = 1; i <= n; i++) {
        c = substr(g, i, 1)
        if (c == "*") { if (substr(g, i + 1, 1) == "*") { re = re ".*"; i++ } else re = re "[^/]*" }
        else if (c == "?") re = re "[^/]"
        else if (c == "{") re = re "("
        else if (c == "}") re = re ")"
        else if (c == ",") re = re "|"
        else if (c == "[" || c == "]") re = re c
        else if (index(".\\^$+()|", c) > 0) re = re "\\" c
        else re = re c
      }
      return anchored ? "^" re "$" : "(^|/)" re "$"
    }
    /^[ \t]*[#;]/ || /^[ \t]*$/ { next }
    /^[ \t]*\[/ { s = $0; sub(/^[ \t]*\[/, "", s); sub(/\][ \t]*$/, "", s); sec = glob2re(s); next }
    sec != "" && /=/ {
      k = $0; sub(/[ \t]*=.*/, "", k); sub(/^[ \t]+/, "", k); k = tolower(k)
      v = $0; sub(/^[^=]*=[ \t]*/, "", v); sub(/[ \t]*(#.*)?$/, "", v); v = tolower(v)
      if (k ~ /^(indent_style|end_of_line|insert_final_newline|trim_trailing_whitespace)$/)
        printf "%s\t%s\t%s\n", sec, k, v
    }' .editorconfig > "$WORK/rules"

  # tracked text files (git grep -I skips binaries); outside git: every text file
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -c core.quotePath=false grep -I -l -e '' -- . > "$WORK/files" 2>/dev/null || true
  else
    find . -type f ! -path './.git/*' ! -path '*/node_modules/*' ! -path './.groma/*' \
      -exec grep -lI '' {} + 2>/dev/null | sed 's#^\./##' | LC_ALL=C sort > "$WORK/files" || true
  fi

  # effective properties per file: file<TAB>indent<TAB>eol<TAB>final<TAB>trim
  awk -F'\t' -v rules="$WORK/rules" '
    BEGIN { while ((getline l < rules) > 0) { n++; split(l, a, "\t"); re[n] = a[1]; key[n] = a[2]; val[n] = a[3] } }
    {
      f = $0; split("", p)
      for (i = 1; i <= n; i++) if (f ~ re[i]) { if (val[i] == "unset") delete p[key[i]]; else p[key[i]] = val[i] }
      if (("indent_style" in p) || ("end_of_line" in p) || ("insert_final_newline" in p) || ("trim_trailing_whitespace" in p))
        printf "%s\t%s\t%s\t%s\t%s\n", f, p["indent_style"], p["end_of_line"], p["insert_final_newline"], p["trim_trailing_whitespace"]
    }' "$WORK/files" > "$WORK/props"

  # final newline needs the last byte; awk cannot see it
  awk -F'\t' '$4 != "" { printf "%s\t%s\n", $1, $4 }' "$WORK/props" > "$WORK/finalcheck"
  : > "$WORK/final"
  while IFS="$TAB" read -r f final; do
    [ -s "$f" ] || continue
    ends=$(tail -c 1 "$f" | wc -l | tr -d ' ')
    case "$final:$ends" in true:0 | false:1) printf '%s\n' "$f" >> "$WORK/final" ;; esac
  done < "$WORK/finalcheck"

  awk -F'\t' -v final="$WORK/final" '
    function hit(prop, f) { cnt[prop]++; if (cnt[prop] <= 5) ex[prop] = (ex[prop] == "" ? f : ex[prop] " " f) }
    BEGIN { while ((getline l < final) > 0) hit("insert_final_newline", l) }
    {
      f = $1; indent = $2; eol = $3; trim = $5
      hi = 0; he = 0; ht = 0
      while ((getline line < f) > 0) {
        if (!hi && indent == "space" && line ~ /^\t/) { hi = 1; hit("indent_style", f) }
        if (!hi && indent == "tab" && line ~ /^  /) { hi = 1; hit("indent_style", f) }
        if (!he && eol == "lf" && line ~ /\r$/) { he = 1; hit("end_of_line", f) }
        if (!he && eol == "crlf" && line !~ /\r$/) { he = 1; hit("end_of_line", f) }
        if (!ht && trim == "true" && line ~ /[ \t]+\r?$/) { ht = 1; hit("trim_trailing_whitespace", f) }
        if ((hi || indent == "") && (he || eol == "") && (ht || trim != "true")) break
      }
      close(f)
    }
    END {
      split("indent_style end_of_line insert_final_newline trim_trailing_whitespace", order, " ")
      for (i = 1; i <= 4; i++) if (cnt[order[i]] > 0) printf "drift\t%s\t%d\t%s\n", order[i], cnt[order[i]], ex[order[i]]
    }' "$WORK/props" > "$WORK/drift"
  drift=$(grep -c . "$WORK/drift" || true)
  cat "$WORK/drift"
fi

# --- (c) unchecked tools -------------------------------------------------------------

printf '%s' "$FOUND" | while IFS="$TAB" read -r id cfg check; do
  [ -n "$id" ] || continue
  mentioned "$id" "$check" || printf 'unchecked%s%s%s%s\n' "$TAB" "$id" "$TAB" "$cfg"
done > "$WORK/unchecked"
unchecked=$(grep -c . "$WORK/unchecked" || true)
cat "$WORK/unchecked"

printf 'summary%stools=%d%sdrift=%d%sunchecked=%d\n' "$TAB" "$tools" "$TAB" "$drift" "$TAB" "$unchecked"
exit 0
