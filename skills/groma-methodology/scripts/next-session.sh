#!/bin/sh
# Claude Code SessionStart hook: give the next action to the agent, once per
# session start, resume, clear or compaction. Runs from the groma plugin
# (hooks/hooks.json).
#
# Usage: next-session.sh [project]
#   project defaults to $CLAUDE_PROJECT_DIR, then to the current directory
#
# Does nothing when <project>/.groma/ is missing (checked first, because a plugin
# hook runs in every project) or when the next action is off: next.hook in
# <project>/.groma/config.yaml is on or off; unset or auto means on exactly when
# the flag file ~/.claude/.groma-next-always exists. That file is only read.
# Output: one line
#   {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<text>"}}
# where <text> ends with the line of next.sh --long. Claude Code adds it to the
# agent's context; it starts no turn. No next action: no output. Stdin is ignored.
# Writes nothing but the cache of next.sh in <project>/.groma/.cache/.
# Exit codes: 0, so that the hook never disturbs the session.
ROOT=""
for arg in "$@"; do
  case "$arg" in
    -*) ;;
    *) ROOT=$arg; break ;;
  esac
done
ROOT=${ROOT:-${CLAUDE_PROJECT_DIR:-.}}
[ -d "$ROOT/.groma" ] || exit 0
set -u

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd) || exit 0
# shellcheck source=SCRIPTDIR/lib-changes.sh
. "$HERE/lib-changes.sh" || exit 0

next_on || exit 0
line=$(sh "$HERE/next.sh" --long "$ROOT" 2>/dev/null || true)
[ -n "$line" ] || exit 0
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
  "$(json_escape "groma next action for this project (for orientation, act on it when the user asks): $line")"
exit 0
