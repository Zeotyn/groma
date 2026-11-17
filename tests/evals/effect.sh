#!/bin/sh
# Effect eval (c013): the same scripted task on a fixture without and with
# groma's setup, several runs per side. Costs API tokens.
#
# Usage: tests/evals/effect.sh [fixture]           (default: go-no-db)
#        tests/evals/effect.sh summary <effect.tsv>
# Task:  effect/<fixture>.md is the prompt, effect/<fixture>.sh <project> the
#        acceptance test; the agent sees neither the test nor this repository.
#        A `# Requires: <cmd>...` line in effect/<fixture>.sh names the commands
#        the acceptance test needs; they are checked before any API call.
# Env:   GROMA_EFFECT_RUNS    runs per side, at least 3 (default 3)
#        GROMA_EFFECT_BUDGET  max USD per task run (default 1)
#        GROMA_EFFECT_SETUP   a set-up project to reuse as the "with" side
#                             instead of running /groma (setup cost then `-`)
#        GROMA_EVAL_BUDGET    max USD for the one /groma setup run (default 3)
#        GROMA_EVAL_DIR       work folder (default: $TMPDIR/groma-effect)
#        GROMA_EVAL_MODEL     model alias for claude -p (default: CLI default)
#        GROMA_EVAL_REPORTS   report folder (default: tests/evals/reports)
#        GROMA_EVAL_ALLOW_USER_SKILLS  see skill-source.sh
# Flow:  states the maximum cost, checks the claude CLI, the user-level skill
#        source (skill-source.sh) and the fixture's commands, then runs /groma
#        once through run.sh (the "with" project) and alternates the task on
#        fresh copies of the plain fixture ("without") and of the set-up
#        project ("with"). Every run works in <work>/run/<fixture>, the same
#        path for both sides, with the sources and earlier runs kept apart in
#        <work>/meta. The report grows in <work> and moves to <reports> only
#        when every run is done; a report of the same day is never
#        overwritten: the eval refuses.
# Limit: both sides load the operator's user-level Claude Code settings,
#        CLAUDE.md and skills alike (CLAUDE_CONFIG_DIR is left as it is,
#        because the login may live there). The report header says so.
# Report: <reports>/effect-<YYYY-MM-DD>.tsv: `#` header lines (fixture, runs,
#         requested model, setup cost and model, the limit above), one row per
#         run (columns of token-report.sh plus run, pass, end, denials, model;
#         end is the result subtype, error_max_budget_usd for a run the budget
#         cap stopped), then per side the median, min and max rows (pass
#         column of the median row: passed/runs) and a `difference median`
#         row, with minus without. Runs without a result count as failed; a
#         `-` value is left out of medians and spread.
# Exit:  0 done (whatever the result), 1 setup failed, 2 usage or report
#        exists, 3 a required command is missing (claude CLI, a fixture's
#        command) or a user-level groma skill shadows this checkout.
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH='' cd -- "$HERE/../.." && pwd)

# shellcheck disable=SC2016 # awk program, expanded by awk
summary_awk='
BEGIN { FS = OFS = "\t" }
$1 == "side" || $2 !~ /^[0-9]+$/ { next }
{
  s = $1
  if (!(s in runs)) order[++nsides] = s
  runs[s]++
  if ($10 == "pass") passed[s]++
  # per column: a `-` (no result, or no turns or duration) is left out, never 0
  for (c = 3; c <= 9; c++) if ($c != "-" && $c != "") v[s, c, ++n[s, c]] = $c + 0
}
function fmt(c, x) { return c == 7 ? sprintf("%.4f", x) : sprintf("%d", int(x + (x < 0 ? -0.5 : 0.5))) }
function stat(s, c, what,   m, i, j, t, a) {
  m = n[s, c]
  for (i = 1; i <= m; i++) a[i] = v[s, c, i]
  for (i = 2; i <= m; i++) { t = a[i]; for (j = i - 1; j >= 1 && a[j] > t; j--) a[j + 1] = a[j]; a[j + 1] = t }
  if (what == "min") return a[1]
  if (what == "max") return a[m]
  return m % 2 ? a[(m + 1) / 2] : (a[m / 2] + a[m / 2 + 1]) / 2
}
END {
  split("median min max", whats, " ")
  for (i = 1; i <= nsides; i++) {
    s = order[i]
    for (w = 1; w <= 3; w++) {
      line = s OFS whats[w]
      for (c = 3; c <= 9; c++) {
        if (n[s, c]) { x = fmt(c, stat(s, c, whats[w])); line = line OFS x; if (w == 1) med[s, c] = x }
        else line = line OFS "-"
      }
      print line OFS (w == 1 ? passed[s] + 0 "/" runs[s] : "-")
    }
  }
  line = "difference" OFS "median"
  for (c = 3; c <= 9; c++) {
    if (n["with", c] && n["without", c]) {
      # from the shown medians; a rounded zero is +0, never -0
      d = fmt(c, med["with", c] - med["without", c])
      if (d + 0 == 0) d = fmt(c, 0)
      line = line OFS (d ~ /^-/ ? "" : "+") d
    } else line = line OFS "-"
  }
  print line OFS sprintf("%+d", passed["with"] - passed["without"])
}'

if [ "${1:-}" = summary ]; then
  if ! { [ $# -eq 2 ] && [ -f "$2" ]; }; then
    echo "usage: effect.sh summary <effect.tsv>" >&2; exit 2
  fi
  awk "$summary_awk" "$2"
  exit 0
fi

FX=${1:-go-no-db}
RUNS=${GROMA_EFFECT_RUNS:-3}
TASK_BUDGET=${GROMA_EFFECT_BUDGET:-1}
SETUP_BUDGET=${GROMA_EVAL_BUDGET:-3}
SETUP=${GROMA_EFFECT_SETUP:-}
case "$RUNS" in ''|*[!0-9]*) RUNS=0 ;; esac
[ "$RUNS" -ge 3 ] || { echo "GROMA_EFFECT_RUNS: at least 3 runs per side" >&2; exit 2; }
if ! { [ -f "$HERE/effect/$FX.md" ] && [ -f "$HERE/effect/$FX.sh" ]; }; then
  echo "no effect task for $FX: need $HERE/effect/$FX.md and .sh" >&2; exit 2
fi
if [ -n "$SETUP" ] && [ ! -d "$SETUP" ]; then
  echo "GROMA_EFFECT_SETUP: not a folder: $SETUP" >&2; exit 2
fi
if [ -n "$SETUP" ]; then SETUP_MAX=0; else SETUP_MAX=$SETUP_BUDGET; fi
max=$(awk -v s="$SETUP_MAX" -v r="$RUNS" -v t="$TASK_BUDGET" 'BEGIN { printf "%.2f", s + 2 * r * t }')
echo "effect $FX: $RUNS runs per side, max cost USD $max (setup $SETUP_MAX + 2 x $RUNS x $TASK_BUDGET)"

WORK=${GROMA_EVAL_DIR:-"${TMPDIR:-/tmp}/groma-effect"}
WORK=${WORK%/}
REPORTS=${GROMA_EVAL_REPORTS:-"$HERE/reports"}
REPORTS=${REPORTS%/}
REPORT="$REPORTS/effect-$(date +%Y-%m-%d).tsv"
[ ! -e "$REPORT" ] || { echo "report exists, not overwritten: $REPORT" >&2; exit 2; }

# every check that can stop the eval runs before the first API call
command -v claude >/dev/null 2>&1 || { echo "claude CLI not found" >&2; exit 3; }
sh "$HERE/skill-source.sh" "$ROOT" || exit $?
needs=$(sed -n 's/^# Requires://p' "$HERE/effect/$FX.sh")
for cmd in $needs; do
  command -v "$cmd" >/dev/null 2>&1 \
    || { echo "effect $FX needs $cmd (acceptance test effect/$FX.sh), not found" >&2; exit 3; }
done

META="$WORK/meta"
PARTIAL="$WORK/effect.tsv"
rm -rf "$WORK"
mkdir -p "$META" "$WORK/run"

if [ -n "$SETUP" ]; then
  echo "== setup: reusing $SETUP"
  WITH_SRC=$SETUP
  setup_cost=-; setup_model=-
else
  echo "== setup: /groma on $FX"
  GROMA_EVAL_DIR="$META/setup" GROMA_EVAL_REPORTS="$META/setup-report" GROMA_EVAL_BUDGET="$SETUP_BUDGET" \
    sh "$HERE/run.sh" "$FX" || { rc=$?; echo "setup failed: /groma eval on $FX exited $rc" >&2; exit 1; }
  WITH_SRC="$META/setup/$FX"
  setup_cost=$(sh "$HERE/token-report.sh" row "$FX" "$META/setup/$FX.json" | cut -f 6)
  setup_model=$(sh "$HERE/token-report.sh" meta "$META/setup/$FX.json" | cut -f 3)
fi
sh "$ROOT/tests/fixtures/generate.sh" "$META/plain" "$FX" >/dev/null

prompt=$(cat "$HERE/effect/$FX.md")
tools="Read Write Edit Glob Grep Bash(sh:*) Bash(go:*) Bash(gofmt:*) Bash(node:*) Bash(npm test:*) Bash(ls:*) Bash(cat:*) Bash(grep:*) Bash(find:*) Bash(printf:*) Bash(echo:*) Bash(mkdir:*) Bash(sed:*) Bash(openspec:*) Bash(git status:*) Bash(git diff:*) Bash(git log:*)"
# the git steps a project's AGENTS.md may ask for; no push target exists in the copies
tools="$tools Bash(git switch:*) Bash(git branch:*) Bash(git add:*) Bash(git commit:*) Bash(git rev-parse:*)"
TAB=$(printf '\t')
{
  echo "# effect $FX, $RUNS runs per side, $(date +%Y-%m-%d), requested model: ${GROMA_EVAL_MODEL:-CLI default}"
  echo "# setup: cost_usd $setup_cost, model $setup_model (not in the medians)"
  echo "# limit: both sides load the operator's user-level Claude Code settings, CLAUDE.md and skills"
  printf 'side\trun\tinput_tokens\toutput_tokens\tcache_read_tokens\tcache_write_tokens\tcost_usd\tturns\tduration_s\tpass\tend\tdenials\tmodel\n'
} > "$PARTIAL"

i=1
while [ "$i" -le "$RUNS" ]; do
  # alternate the sides and their order, so drift and prompt caching hit both alike
  if [ $((i % 2)) -eq 1 ]; then sides="without with"; else sides="with without"; fi
  for side in $sides; do
    if [ "$side" = with ]; then src=$WITH_SRC; else src="$META/plain/$FX"; fi
    P="$WORK/run/$FX"
    cp -R "$src" "$P"
    echo "== $side $i"
    set +e
    # shellcheck disable=SC2086
    (cd "$P" && claude -p "$prompt" \
        --permission-mode acceptEdits \
        --allowedTools "$tools" \
        --max-budget-usd "$TASK_BUDGET" \
        ${GROMA_EVAL_MODEL:+--model "$GROMA_EVAL_MODEL"} \
        --output-format json > "$META/$side-$i.json" 2> "$META/$side-$i.log")
    set -e
    if sh "$HERE/effect/$FX.sh" "$P" > "$META/$side-$i.accept" 2>&1; then pass=pass; else pass=fail; fi
    mv "$P" "$META/$side-$i"
    row=$(sh "$HERE/token-report.sh" row "$side" "$META/$side-$i.json")
    meta=$(sh "$HERE/token-report.sh" meta "$META/$side-$i.json")
    printf '%s\t%s\t%s\t%s\t%s\n' "$side" "$i" "${row#*"$TAB"}" "$pass" "$meta" >> "$PARTIAL"
    echo "   $pass (acceptance: $META/$side-$i.accept)"
    case "$meta" in
      error_max_budget_usd"$TAB"*) echo "   stopped by the budget cap (USD $TASK_BUDGET)" ;;
    esac
    case "$meta" in
      *"$TAB"0"$TAB"*|-"$TAB"*) ;;
      *) echo "   permission denials: $(printf '%s' "$meta" | cut -f 2) (see $META/$side-$i.json)" ;;
    esac
  done
  i=$((i + 1))
done

summary=$(awk "$summary_awk" "$PARTIAL")
printf '%s\n' "$summary" >> "$PARTIAL"
mkdir -p "$REPORTS"
mv "$PARTIAL" "$REPORT"
echo "== effect, report: $REPORT"
printf '%s\n' "$summary"
