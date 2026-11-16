#!/bin/sh
# Check a survey findings report before it is handed back. Read-only.
#
# Usage: report-check.sh <findings-report.md>
#
# The report is complete when it has every `## ` section of
# templates/findings.md (next to this script's folder), no `{{` placeholder,
# and a `## Hand-off` section of 1 to 10 non-empty lines: the lines a survey
# run in a subagent returns to the main session with the report path.
#
# Output, tab-separated:
#   missing<TAB><heading>        one line per template section not in the report
#   placeholder<TAB><line>       one line per report line with `{{`
#   handoff<TAB><n>              non-empty lines in the Hand-off section (0 when absent)
#   summary<TAB>ok|incomplete
# Exit 0 complete, 1 incomplete, 2 usage error or unreadable report.
set -eu

[ $# -eq 1 ] || { sed -n '4p' "$0" | sed 's/^# //' >&2; exit 2; }
R=$1
if [ ! -f "$R" ] || [ ! -r "$R" ]; then echo "report not found: $R" >&2; exit 2; fi
T=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)/templates/findings.md
[ -f "$T" ] || { echo "template not found: $T" >&2; exit 2; }

awk '
FNR == NR { if (/^## /) { sub(/[ \t\r]+$/, ""); want[++n] = $0 } next }
{
  line = $0; sub(/[ \t\r]+$/, "", line)
  if (line ~ /^## /) { have[line] = 1; inhand = (line == "## Hand-off"); next }
  if (index(line, "{{")) { printf "placeholder\t%d\n", FNR; ph = 1 }
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
