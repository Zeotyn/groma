#!/bin/sh
# Check a survey findings report before it is handed back. Read-only.
#
# Usage: report-check.sh <findings-report.md>
#
# The report is complete when it has the `generated_by:` line of the
# frontmatter of templates/findings.md (next to this script's folder), every
# `## ` section of the template (a heading matches by its text before ` (`),
# content in each section other than the hand-off (a table without rows needs
# a line such as "None found."), no placeholder of the template left, and a
# first `## Hand-off` section of 1 to 10 non-empty lines: the lines a survey
# run in a subagent returns to the main session with the report.
# A placeholder is `{{<name>}}` or `{{<name>: ...}}` with a <name> the template
# uses. Fenced code blocks are skipped, and so are inline code spans unless
# the span is exactly one placeholder; other braces (Helm, Jinja, Vue
# evidence) never count.
#
# Output, tab-separated:
#   missing<TAB><line>           one line per template section (`## ...`) or
#                                frontmatter line (`generated_by: ...`) not in the report
#   empty<TAB><heading>          one line per template section without content
#   placeholder<TAB><line>       one line per report line with a placeholder
#   handoff<TAB><n>              non-empty lines in the first Hand-off section (0 when absent)
#   summary<TAB>ok|incomplete
# Exit 0 complete, 1 incomplete, 2 usage error or unreadable report.
set -eu

[ $# -eq 1 ] || { sed -n '4p' "$0" | sed 's/^# //' >&2; exit 2; }
R=$1
if [ ! -f "$R" ] || [ ! -r "$R" ]; then echo "report not found: $R" >&2; exit 2; fi
T=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)/templates/findings.md
[ -f "$T" ] || { echo "template not found: $T" >&2; exit 2; }

awk '
function trim(t) { sub(/[ \t\r]+$/, "", t); return t }
function key(h) { h = trim(h); sub(/ \(.*$/, "", h); return h }
function names(t,   m) { # placeholder names in t
  while (match(t, /\{\{[a-z_]+[:}]/)) {
    m = substr(t, RSTART + 2, RLENGTH - 3); pname[m] = 1
    t = substr(t, RSTART + RLENGTH)
  }
}
function has_placeholder(t,   out, span, m) {
  out = ""
  while (match(t, /`[^`]*`/)) { # keep a span only when it is exactly one placeholder
    span = substr(t, RSTART + 1, RLENGTH - 2)
    out = out substr(t, 1, RSTART - 1) (span ~ /^\{\{[a-z_]+(:[^}]*)?\}\}$/ ? span : " ")
    t = substr(t, RSTART + RLENGTH)
  }
  t = out t
  while (match(t, /\{\{[a-z_]+[:}]/)) {
    m = substr(t, RSTART + 2, RLENGTH - 3)
    if (m in pname) return 1
    t = substr(t, RSTART + RLENGTH)
  }
  return 0
}
function genby(t) { sub(/^generated_by:[ \t]*/, "generated_by: ", t); return t }
FNR == NR { # the template: its generated_by line, its sections, its placeholder names
  line = trim($0)
  if (FNR == 1 && line == "---") { tfm = 1; next }
  if (tfm) { if (line == "---") tfm = 0; else if (line ~ /^generated_by:/) wantfm = genby(line); next }
  if (line ~ /^## /) want[++n] = key(line)
  names(line); next
}
{
  line = trim($0)
  if (FNR == 1 && line == "---") { fm = 1; next }
  if (fm) { if (line == "---") fm = 0; else if (line ~ /^generated_by:/) havefm[genby(line)] = 1; next }
  if (line ~ /^(```|~~~)/) { fence = !fence; if (cur != "") body[cur]++; next }
  if (fence) next
  if (line ~ /^## /) {
    cur = key(line); have[cur] = 1; row = 0
    inhand = (cur == "## Hand-off" && !seenhand); if (inhand) seenhand = 1
    next
  }
  if (has_placeholder(line)) { printf "placeholder\t%d\n", FNR; ph = 1 }
  if (inhand && line != "") hand++
  # content: text lines and table rows below a separator; a table header is none
  if (line ~ /^\|/) {
    if (line ~ /^\|[ \t:|-]+$/) row = 1
    else if (row && cur != "") body[cur]++
  } else {
    row = 0
    if (line != "" && cur != "") body[cur]++
  }
}
END {
  bad = 0
  if (wantfm != "" && !(wantfm in havefm)) { printf "missing\t%s\n", wantfm; bad = 1 }
  for (i = 1; i <= n; i++) {
    if (!(want[i] in have)) { printf "missing\t%s\n", want[i]; bad = 1 }
    else if (want[i] != "## Hand-off" && !body[want[i]]) { printf "empty\t%s\n", want[i]; bad = 1 }
  }
  if (ph) bad = 1
  printf "handoff\t%d\n", hand + 0
  if (hand < 1 || hand > 10) bad = 1
  print "summary\t" (bad ? "incomplete" : "ok")
  exit bad
}' "$T" "$R"
