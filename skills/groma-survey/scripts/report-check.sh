#!/bin/sh
# Check a survey findings report before it is handed back. Read-only.
#
# Usage: report-check.sh <findings-report.md>
#
# The report is complete when it has every `## ` section of
# templates/findings.md (next to this script's folder; a heading matches by
# its text before ` (`), no placeholder of the template left, and a first
# `## Hand-off` section of 1 to 10 non-empty lines: the lines a survey run in
# a subagent returns to the main session with the report path.
# A placeholder is `{{<name>}}` or `{{<name>: ...}}` with a <name> the template
# uses. Fenced code blocks are skipped, and so are inline code spans unless
# the span is exactly one placeholder; other braces (Helm, Jinja, Vue
# evidence) never count.
#
# Output, tab-separated:
#   missing<TAB><heading>        one line per template section not in the report
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
function key(h) { sub(/[ \t\r]+$/, "", h); sub(/ \(.*$/, "", h); return h }
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
FNR == NR { if (/^## /) want[++n] = key($0); names($0); next }
{
  line = $0; sub(/[ \t\r]+$/, "", line)
  if (line ~ /^(```|~~~)/) { fence = !fence; next }
  if (fence) next
  if (line ~ /^## /) {
    k = key(line); have[k] = 1
    inhand = (k == "## Hand-off" && !seenhand); if (inhand) seenhand = 1
    next
  }
  if (has_placeholder(line)) { printf "placeholder\t%d\n", FNR; ph = 1 }
  if (inhand && line != "") hand++
}
END {
  bad = 0
  for (i = 1; i <= n; i++) if (!(want[i] in have)) { printf "missing\t%s\n", want[i]; bad = 1 }
  if (ph) bad = 1
  printf "handoff\t%d\n", hand + 0
  if (hand < 1 || hand > 10) bad = 1
  print "summary\t" (bad ? "incomplete" : "ok")
  exit bad
}' "$T" "$R"
