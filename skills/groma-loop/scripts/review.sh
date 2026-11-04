#!/bin/sh
# Run one read-only review through another agent's CLI.
#
#   review.sh <reviewer> <prompt-file> <output-file> [--timeout <s>]
#   review.sh --probe <reviewer> [--timeout <s>]
#
# reviewer: claude[:model] | gemini[:model] | copilot[:model] | codex[:model]
#           ("self" is done by the author agent in a fresh context, not here)
#
# The answer must be a findings table
#   | id | severity | location | finding | suggestion |   (severity: high|medium|low)
# or the line "NO FINDINGS". A malformed answer is retried once with a format
# reminder; a second malformed answer is recorded as one medium finding
# "unparseable review" with the raw text attached.
#
# Output file: "reviewer: <r>", "status: ok|retried|unparseable", then the table.
# Exit codes: 0 review written, 2 usage, 4 self-review requested,
#             5 CLI missing, failed or timed out.
set -eu

TIMEOUT=600
PROBE=0
P1="" P2="" P3=""
while [ $# -gt 0 ]; do
  case "$1" in
    --probe) PROBE=1; shift ;;
    --timeout) TIMEOUT=$2; shift 2 ;;
    *) if [ -z "$P1" ]; then P1=$1; elif [ -z "$P2" ]; then P2=$1; else P3=$1; fi; shift ;;
  esac
done

REVIEWER=$P1
[ -n "$REVIEWER" ] || { echo "usage: $0 <reviewer> <prompt-file> <output-file> | --probe <reviewer>" >&2; exit 2; }
AGENT=${REVIEWER%%:*}
MODEL=""
case "$REVIEWER" in *:*) MODEL=${REVIEWER#*:} ;; esac

if [ "$AGENT" = self ]; then
  echo "self-review: the author agent reviews in a fresh context (new subagent or session); review.sh cannot run it" >&2
  exit 4
fi
case "$AGENT" in claude|gemini|copilot|codex) ;; *) echo "unknown reviewer agent: $AGENT" >&2; exit 2 ;; esac
command -v "$AGENT" >/dev/null 2>&1 || { echo "$AGENT CLI not installed" >&2; exit 5; }

TMP=$(mktemp "${TMPDIR:-/tmp}/groma-review.XXXXXX")
trap 'rm -f "$TMP"' EXIT

# Runs the reviewer CLI headless and read-only with the prompt text in $1.
# Output goes to $TMP. Returns the CLI's exit code (or 124 on timeout).
call() {
  text=$1
  case "$AGENT" in
    claude)  set -- claude -p "$text" --permission-mode plan ${MODEL:+--model "$MODEL"} ;;
    gemini)  set -- gemini -p "$text" ${MODEL:+-m "$MODEL"} ;;
    copilot) set -- copilot -p "$text" ${MODEL:+--model "$MODEL"} ;;
    codex)   set -- codex exec --sandbox read-only ${MODEL:+-m "$MODEL"} "$text" ;;
  esac
  "$@" > "$TMP" 2>&1 &
  pid=$!
  # watchdog: its own sleep dies with it, and it holds no stdout/stderr open
  (
    trap 'kill "$s" 2>/dev/null; exit 0' TERM
    sleep "$TIMEOUT" & s=$!
    wait "$s" && kill "$pid" 2>/dev/null
  ) >/dev/null 2>&1 &
  watcher=$!
  rc=0
  wait "$pid" || rc=$?
  kill "$watcher" 2>/dev/null || true
  wait "$watcher" 2>/dev/null || true
  return "$rc"
}

if [ "$PROBE" -eq 1 ]; then
  [ "$TIMEOUT" -eq 600 ] && TIMEOUT=60
  if call "Reply with the single word OK." && grep -qi 'ok' "$TMP"; then
    echo "probe ok: $REVIEWER"
    exit 0
  fi
  echo "probe failed: $REVIEWER ($(head -c 200 "$TMP" | tr '\n' ' '))" >&2
  exit 5
fi

PROMPT_FILE=$P2
OUT=$P3
if [ -z "$PROMPT_FILE" ] || [ ! -f "$PROMPT_FILE" ] || [ -z "$OUT" ]; then
  echo "usage: $0 <reviewer> <prompt-file> <output-file>" >&2; exit 2
fi

# valid when it says NO FINDINGS, or has the header and only rows with a known severity
valid() {
  grep -qx 'NO FINDINGS' "$1" && return 0
  awk '
    tolower($0) ~ /^\| *id *\| *severity *\| *location *\| *finding *\| *suggestion *\|/ { head = 1; next }
    head && /^\|[-:| ]+\|$/ { next }
    head && /^\|/ {
      n = split($0, c, "|"); s = tolower(c[3]); gsub(/ /, "", s)
      if (s != "high" && s != "medium" && s != "low") bad = 1
      rows++
      next
    }
    END { exit !(head && !bad) }
  ' "$1"
}

table_of() { # print NO FINDINGS or the table lines
  if grep -qx 'NO FINDINGS' "$1"; then echo "NO FINDINGS"; return; fi
  awk 'tolower($0) ~ /^\| *id *\| *severity/ { on = 1 } on && /^\|/ { print } on && !/^\|/ { exit }' "$1"
}

REMINDER='

FORMAT REMINDER: answer with exactly one Markdown table with the header
| id | severity | location | finding | suggestion |
(severity is high, medium or low), or with the single line NO FINDINGS. No other text.'

status=ok
call "$(cat "$PROMPT_FILE")" || { echo "$AGENT failed (exit $?): $(head -c 300 "$TMP" | tr '\n' ' ')" >&2; exit 5; }
if ! valid "$TMP"; then
  status=retried
  call "$(cat "$PROMPT_FILE")$REMINDER" || { echo "$AGENT failed on retry" >&2; exit 5; }
  valid "$TMP" || status=unparseable
fi

{
  echo "reviewer: $REVIEWER"
  echo "status: $status"
  echo
  if [ "$status" = unparseable ]; then
    echo '| id | severity | location | finding | suggestion |'
    echo '|---|---|---|---|---|'
    echo '| R1 | medium | - | unparseable review | read the raw answer below or rerun the review |'
    echo
    echo '## Raw answer'
    echo
    cat "$TMP"
  else
    table_of "$TMP"
  fi
} > "$OUT"
echo "review written: $OUT ($status)"
