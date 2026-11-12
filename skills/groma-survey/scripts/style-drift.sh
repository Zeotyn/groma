#!/bin/sh
# Static code-style report. Read-only, runs no project tool.
#
# Usage: style-drift.sh [--table <code-style-tools.md>] [<project>]
#
# (a) tool: a style tool whose config pattern from the reference table matches
#     a file at the project root (`file#text`: the file contains text). When a
#     `file#text` match and a bare match name the same file, the `#text` tool
#     wins (typescript-eslint over ESLint on one eslint.config.js).
# (b) drift: tracked text files that disagree with the root `.editorconfig`
#     on indent_style, end_of_line, insert_final_newline or
#     trim_trailing_whitespace. Sections are applied in file order, the last
#     matching section wins, `unset` lifts a property. indent_style=space flags
#     lines starting with a tab, indent_style=tab lines starting with two or
#     more spaces. Nested .editorconfig files are not read. Outside git, every
#     text file below the project is checked except .git, .groma and
#     node_modules.
# (c) checked / unchecked: for each tool with a check command, the first place
#     from the table's "Where checks run" section that mentions the tool (its
#     name, or the first two words of its check command without the runner
#     prefixes listed in the table) and the command found there; a tool with no
#     such place is unchecked.
#
# Output, tab-separated:
#   note<TAB><text>
#   tool<TAB><tool><TAB><config path><TAB><check command>
#   drift<TAB><property><TAB><file count><TAB><up to five paths, space-separated>
#   checked<TAB><tool><TAB><file><TAB><command, e.g. npm run lint, make lint, run: ruff check .>
#   unchecked<TAB><tool><TAB><config path>
#   summary<TAB>tools=<n><TAB>drift=<n><TAB>unchecked=<n>
# Exit 0; usage errors exit 2.
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TABLE="$HERE/../references/code-style-tools.md"
DIR=.
while [ $# -gt 0 ]; do
  case "$1" in
    --table) TABLE=$2; shift 2 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) DIR=$1; shift ;;
  esac
done
[ -d "$DIR" ] || { echo "not a directory: $DIR" >&2; exit 2; }
case "$TABLE" in /*) ;; *) TABLE="$PWD/$TABLE" ;; esac
cd "$DIR"
TAB=$(printf '\t')
NL='
'
WORK=$(mktemp -d "${TMPDIR:-/tmp}/style-drift.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
trap 'rm -rf "$WORK"; exit 130' INT TERM

tools=0 drift=0 unchecked=0

# --- table readers ---------------------------------------------------------------------

# chosen cells (1-based markdown columns) of the table whose header starts with
# "| <first> |", trimmed, backticks removed, tab-separated; empty cells only last,
# because a tab-separated `read` collapses empty fields
table_cols() { # first-column-header col...
  first=$1; shift
  awk -F'|' -v first="$first" -v cols="$*" '
    BEGIN { n = split(cols, want, " ") }
    $0 ~ "^\\| *" first " *\\|" { intable = 1; next }
    intable && /^\|/ {
      if ($2 ~ /^ *:?-+:? *$/) next
      out = ""
      for (i = 1; i <= n; i++) { c = $(want[i] + 1); gsub(/^ +| +$/, "", c); gsub(/`/, "", c); out = out (i > 1 ? "\t" : "") c }
      print out; next
    }
    intable && !/^\|/ { intable = 0 }' "$TABLE"
}

# first existing file for a comma-separated pattern list; prints path<TAB>specific(0|1)
find_config() {
  oldifs=$IFS; IFS=','
  for pat in $1; do
    IFS=$oldifs
    pat=${pat# }; pat=${pat% }
    text=""
    case "$pat" in *'#'*) text=${pat#*#}; pat=${pat%%#*} ;; esac
    for f in $pat; do
      [ -f "$f" ] || continue
      if [ -z "$text" ]; then
        printf '%s\t0\n' "$f"; IFS=$oldifs; return 0
      elif grep -qF -- "$text" "$f" 2>/dev/null; then
        printf '%s\t1\n' "$f"; IFS=$oldifs; return 0
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
    !found && index($0, "\"scripts\"") { found = 1; $0 = substr($0, index($0, "\"scripts\"")) }
    found {
      n = split($0, ch, "")
      for (i = 1; i <= n; i++) {
        if (ch[i] == "{") depth++
        else if (ch[i] == "}") { depth--; if (depth == 0) { print; exit } }
      }
      print
    }' "$1"
}

# where a tool is mentioned: prints file<TAB>command, or fails
mentioned() { # tool-id needle-words
  while IFS="$TAB" read -r kind pat cmd; do
    [ -n "$kind" ] || continue
    for f in $pat; do
      [ -f "$f" ] || continue
      case "$kind" in
        package-scripts)
          hit=$(package_scripts "$f" | tr '\n' ' ' | awk -v a="$1" -v b="$2" '
            { s = $0
              while (match(s, /"[^"]*"[ \t]*:[ \t]*"[^"]*"/)) {
                pair = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
                split(pair, q, "\""); key = q[2]; val = tolower(q[4])
                if (key != "scripts" && (index(val, a) || (b != "" && index(val, b)))) { print key; exit }
              } }') ;;
        targets)
          hit=$(awk -v a="$1" -v b="$2" '
            /^[A-Za-z0-9_.\/-]+[ \t]*:/ { t = $0; sub(/[ \t]*:.*/, "", t) }
            { l = tolower($0); if (t != "" && (index(l, a) || (b != "" && index(l, b)))) { print t; exit } }' "$f") ;;
        *)
          hit=$(awk -v a="$1" -v b="$2" '
            { l = tolower($0); if (index(l, a) || (b != "" && index(l, b))) { sub(/^[ \t-]+/, ""); sub(/[ \t\r]+$/, ""); print; exit } }' "$f") ;;
      esac
      if [ -n "$hit" ]; then
        case "$cmd" in
          *'{script}'*) out="${cmd%%\{script\}*}$hit${cmd#*\{script\}}" ;;
          *'{target}'*) out="${cmd%%\{target\}*}$hit${cmd#*\{target\}}" ;;
          *) out=$hit ;;
        esac
        printf '%s\t%s\n' "$f" "$out"; return 0
      fi
    done
  done <<EOF
$LOCATIONS
EOF
  return 1
}

# the check command without the longest runner prefix from the table, first two words
needle_words() {
  w=$1 best=""
  while IFS="$TAB" read -r p; do
    [ -n "$p" ] || continue
    case "$w" in "$p "*) [ ${#p} -gt ${#best} ] && best=$p ;; esac
  done <<EOF
$PREFIXES
EOF
  [ -n "$best" ] && w=${w#"$best "}
  printf '%s' "$w" | awk '{ print ($2 == "" ? $1 : $1 " " $2) }'
}

# --- (a) tools -----------------------------------------------------------------------

FOUND=""
if [ -f "$TABLE" ]; then
  LOCATIONS=$(table_cols Kind 1 2 3)
  PREFIXES=$(table_cols Prefix 1)
  matches=""
  while IFS="$TAB" read -r tool pat check; do
    [ -n "$tool" ] || continue
    m=$(find_config "$pat") || continue
    id=$(printf '%s' "$tool" | tr '[:upper:] ' '[:lower:]-')
    matches="$matches$id$TAB$m$TAB$check$NL"
  done <<EOF
$(table_cols Stack 2 4 5)
EOF
  specific=$(printf '%s' "$matches" | awk -F'\t' '$3 == 1 { print $2 }')
  printf '%s' "$matches" | while IFS="$TAB" read -r id cfg spec check; do
    [ -n "$id" ] || continue
    if [ "$spec" = 0 ] && printf '%s\n' "$specific" | grep -qxF -- "$cfg"; then continue; fi
    printf 'tool%s%s%s%s%s%s\n' "$TAB" "$id" "$TAB" "$cfg" "$TAB" "$check"
  done > "$WORK/tools"
  tools=$(grep -c . "$WORK/tools" || true)
  cat "$WORK/tools"
  FOUND=$(awk -F'\t' '$4 != "" { printf "%s\t%s\t%s\n", $2, $3, $4 }' "$WORK/tools")
else
  printf 'note%sstyle tools not detected (code-style-tools.md missing)\n' "$TAB"
fi

# --- (b) editorconfig drift ------------------------------------------------------------

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
        else if (c == "[") { if (substr(g, i + 1, 1) == "!") { re = re "[^"; i++ } else re = re "[" }
        else if (c == "]") re = re c
        else if (index(".\\^$+()|", c) > 0) re = re "\\" c
        else re = re c
      }
      return anchored ? "^" re "$" : "(^|/)" re "$"
    }
    { sub(/\r$/, "") }
    /^[ \t]*[#;]/ || /^[ \t]*$/ { next }
    /^[ \t]*\[/ { s = $0; sub(/^[ \t]*\[/, "", s); sub(/\][ \t]*$/, "", s); sec = glob2re(s); next }
    sec != "" && /=/ {
      k = $0; sub(/[ \t]*=.*/, "", k); sub(/^[ \t]+/, "", k); k = tolower(k)
      v = $0; sub(/^[^=]*=[ \t]*/, "", v); sub(/[ \t]*(#.*)?$/, "", v); v = tolower(v)
      if (k ~ /^(indent_style|end_of_line|insert_final_newline|trim_trailing_whitespace)$/)
        printf "%s\t%s\t%s\n", sec, k, v
    }' .editorconfig > "$WORK/rules"

  # tracked text files (git grep -I skips binaries); outside git: every text file.
  # Paths get a ./ prefix so that names starting with - or a file named - are safe.
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -c core.quotePath=false grep -I -l -e '' -- . 2>/dev/null | sed 's#^#./#' > "$WORK/files" || true
  else
    find . -type f ! -path './.git/*' ! -path '*/node_modules/*' ! -path './.groma/*' \
      -exec grep -lI '' {} + 2>/dev/null | LC_ALL=C sort > "$WORK/files" || true
  fi

  # effective properties per file: file<TAB>indent<TAB>eol<TAB>final<TAB>trim
  # (matched without the ./ prefix)
  awk -F'\t' -v rules="$WORK/rules" '
    BEGIN { while ((getline l < rules) > 0) { n++; split(l, a, "\t"); re[n] = a[1]; key[n] = a[2]; val[n] = a[3] } }
    {
      f = substr($0, 3); split("", p)
      for (i = 1; i <= n; i++) if (f ~ re[i]) { if (val[i] == "unset") delete p[key[i]]; else p[key[i]] = val[i] }
      if (("indent_style" in p) || ("end_of_line" in p) || ("insert_final_newline" in p) || ("trim_trailing_whitespace" in p))
        printf "%s\t%s\t%s\t%s\t%s\n", $0, p["indent_style"], p["end_of_line"], p["insert_final_newline"], p["trim_trailing_whitespace"]
    }' "$WORK/files" > "$WORK/props"

  # byte sizes in one batch, for the final-newline check: awk sums the lines it reads
  # (bytes in the C locale) and compares with the size; one byte more means no newline
  awk -F'\t' '$4 != "" { print $1 }' "$WORK/props" | tr '\n' '\0' | xargs -0 wc -c 2>/dev/null \
    | awk '/^ *[0-9]+ \.\// { n = $1; sub(/^ *[0-9]+ /, ""); printf "%s\t%s\n", $0, n }' > "$WORK/sizes" || true

  LC_ALL=C awk -F'\t' -v sizes="$WORK/sizes" '
    function hit(prop, f) { cnt[prop]++; if (cnt[prop] <= 5) ex[prop] = (ex[prop] == "" ? f : ex[prop] " " f) }
    BEGIN { while ((getline l < sizes) > 0) { split(l, a, "\t"); size[a[1]] = a[2] } }
    {
      f = $1; indent = $2; eol = $3; final = $4; trim = $5; show = substr(f, 3)
      hi = 0; he = 0; ht = 0; bytes = 0; lines = 0
      count = (final != "" && (f in size))
      while ((getline line < f) > 0) {
        lines++
        if (count) bytes += length(line) + 1
        if (!hi && indent == "space" && line ~ /^\t/) { hi = 1; hit("indent_style", show) }
        if (!hi && indent == "tab" && line ~ /^  /) { hi = 1; hit("indent_style", show) }
        if (!he && eol == "lf" && line ~ /\r$/) { he = 1; hit("end_of_line", show) }
        if (!he && eol == "crlf" && line !~ /\r$/) { he = 1; hit("end_of_line", show) }
        if (!ht && trim == "true" && line ~ /[ \t]+\r?$/) { ht = 1; hit("trim_trailing_whitespace", show) }
        if (!count && (hi || indent == "") && (he || eol == "") && (ht || trim != "true")) break
      }
      close(f)
      if (count && lines > 0) {
        ends = (bytes == size[f] + 0)
        if ((final == "true" && !ends) || (final == "false" && ends)) hit("insert_final_newline", show)
      }
    }
    END {
      split("indent_style end_of_line insert_final_newline trim_trailing_whitespace", order, " ")
      for (i = 1; i <= 4; i++) if (cnt[order[i]] > 0) printf "drift\t%s\t%d\t%s\n", order[i], cnt[order[i]], ex[order[i]]
    }' "$WORK/props" > "$WORK/drift"
  drift=$(grep -c . "$WORK/drift" || true)
  cat "$WORK/drift"
fi

# --- (c) checked and unchecked tools --------------------------------------------------

printf '%s\n' "$FOUND" | while IFS="$TAB" read -r id cfg check; do
  [ -n "$id" ] || continue
  words=$(needle_words "$check" | tr '[:upper:]' '[:lower:]')
  if where=$(mentioned "$id" "$words"); then
    printf 'checked%s%s%s%s\n' "$TAB" "$id" "$TAB" "$where"
  else
    printf 'unchecked%s%s%s%s\n' "$TAB" "$id" "$TAB" "$cfg"
  fi
done > "$WORK/checks"
unchecked=$(grep -c '^unchecked' "$WORK/checks" || true)
cat "$WORK/checks"

printf 'summary%stools=%d%sdrift=%d%sunchecked=%d\n' "$TAB" "$tools" "$TAB" "$drift" "$TAB" "$unchecked"
exit 0
