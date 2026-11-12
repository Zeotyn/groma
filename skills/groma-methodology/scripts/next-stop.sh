#!/bin/sh
# Claude Code Stop hook: show the next action to the user, debounced.
#
# Usage: next-stop.sh [--stderr] [--now <epoch>] [project]
#   project defaults to the current directory; --now replaces the clock in tests
#
# Does nothing unless next.hook is on in <project>/.groma/config.yaml.
# Output: one line {"systemMessage":"▶ Next: <next.sh --long>"} when the line
# differs from the last one shown, or when that showing is next.reshow_minutes
# old (default 30; 0 shows only on change). Otherwise nothing. The message goes
# to the user only: no decision, no retry, no text for the agent.
# With --stderr (Copilot CLI agentStop, which shows the stderr of an exit 2 to
# the user without a new turn) the line goes to stderr as plain text
# "▶ Next: <line>" with exit 2, and stdout stays empty.
# State: <project>/.groma/.cache/next-shown (epoch, line); removed when there is no
# next action. Stdin is ignored.
# Exit codes: 0, so that the hook never disturbs the session; 2 only with
#   --stderr when the line is shown.
set -u

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd) || exit 0
# shellcheck source=SCRIPTDIR/lib-changes.sh
. "$HERE/lib-changes.sh" || exit 0

NOW=""
ROOT=.
STDERR=0
while [ $# -gt 0 ]; do
  case "$1" in
    --now) NOW=${2:-}; shift; [ $# -eq 0 ] || shift ;;
    --stderr) STDERR=1; shift ;;
    -*) shift ;;
    *) ROOT=$1; shift ;;
  esac
done

[ "$(cfg_value hook off next)" = on ] || exit 0
MINUTES=$(cfg_value reshow_minutes 30 next)
case "$MINUTES" in ''|*[!0-9]*) MINUTES=30 ;; esac
MINUTES=${MINUTES#"${MINUTES%%[!0]*}"}   # 08 is decimal, not a bad octal number
MINUTES=${MINUTES:-0}
case "$NOW" in ''|*[!0-9]*) NOW=$(date +%s) ;; esac

STATE="$ROOT/.groma/.cache/next-shown"
mkdir -p "$ROOT/.groma/.cache" 2>/dev/null
[ -e "$ROOT/.groma/.cache/.gitignore" ] || echo '*' > "$ROOT/.groma/.cache/.gitignore" 2>/dev/null
line=$(sh "$HERE/next.sh" --long "$ROOT" 2>/dev/null || true)
if [ -z "$line" ]; then
  rm -f "$STATE" 2>/dev/null
  exit 0
fi

shown_at=0
shown=""
if [ -f "$STATE" ]; then
  { IFS= read -r shown_at; IFS= read -r shown; } < "$STATE" || true
fi
case "$shown_at" in ''|*[!0-9]*) shown_at=0 ;; esac

show=0
[ "$line" = "$shown" ] || show=1
if [ "$MINUTES" -gt 0 ] && [ $((NOW - shown_at)) -ge $((MINUTES * 60)) ]; then show=1; fi
[ "$show" -eq 1 ] || exit 0

printf '%s\n%s\n' "$NOW" "$line" > "$STATE" 2>/dev/null || true
if [ "$STDERR" -eq 1 ]; then
  printf '▶ Next: %s\n' "$line" >&2
  exit 2
fi
printf '{"systemMessage":"▶ Next: %s"}\n' "$(json_escape "$line")"
exit 0
