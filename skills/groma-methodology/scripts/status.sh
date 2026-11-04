#!/bin/sh
# Lifecycle reminders for active changes. Read-only, git and file reads only.
#
# Usage: status.sh [--root <project>] [--today YYYY-MM-DD]
#
# One line per active change that needs attention, at most one reminder each,
# in this priority:
#   all tasks done                         -> verify, then archive
#   tasks ticked after the last test change -> add or run tests (not for m/d changes)
#   no commit for stale_change_days        -> continue or close
# Nothing to report: "groma status: nothing open".
# Toggles: reminders.archive_when_done, reminders.untested_tasks,
#          reminders.stale_change_days (0 disables) in .groma/config.yaml.
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=SCRIPTDIR/lib-changes.sh
. "$HERE/lib-changes.sh"

ROOT=.
TODAY=$(date -u +%Y-%m-%d)
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=$2; shift 2 ;;
    --today) TODAY=$2; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

cfg_value() { # key default
  v=""
  [ -f "$ROOT/.groma/config.yaml" ] && v=$(awk -v k="$1" '
    function ind(s) { match(s, /^ */); return RLENGTH }
    /^[ ]*#/ || /^[ ]*$/ { next }
    { i = ind($0); l = $0; sub(/^ */, "", l); sub(/[ ]+#.*/, "", l)
      if (inr && i == 0) inr = 0
      if (l ~ /^reminders:/ && i == 0) { inr = 1; next }
      if (inr && index(l, k ":") == 1) { sub(/^[^:]*:[ ]*/, "", l); print l; exit } }' "$ROOT/.groma/config.yaml")
  echo "${v:-$2}"
}
ARCHIVE_WHEN_DONE=$(cfg_value archive_when_done true)
UNTESTED=$(cfg_value untested_tasks true)
STALE_DAYS=$(cfg_value stale_change_days 14)

days() { # YYYY-MM-DD -> days since epoch
  echo "$1" | awk -F- '{ y = $1 + 0; m = $2 + 0; d = $3 + 0; if (m <= 2) { y--; m += 12 }
    era = int(y / 400); yoe = y - era * 400; doy = int((153 * (m - 3) + 2) / 5) + d - 1
    print era * 146097 + yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy - 719468 }'
}
TODAY_DAYS=$(days "$TODAY")

in_git=0
git -C "$ROOT" rev-parse HEAD >/dev/null 2>&1 && in_git=1

last_commit() { # epoch of the newest commit touching the paths (relative to ROOT), 0 if none
  [ "$in_git" -eq 1 ] || { echo 0; return; }
  t=$(git -C "$ROOT" log -1 --format=%ct -- "$@" 2>/dev/null || true)
  echo "${t:-0}"
}
dirty() { # 0 when the path has uncommitted changes
  [ "$in_git" -eq 1 ] || return 1
  [ -n "$(git -C "$ROOT" status --porcelain -- "$1" 2>/dev/null)" ]
}

# newest commit touching test files: test folders or test file name conventions,
# never methodology folders (OpenSpec's spec.md files are not tests)
TEST_EPOCH=0
if [ "$in_git" -eq 1 ]; then
  TEST_EPOCH=$(git -C "$ROOT" log -1 --format=%ct -- \
    ':(glob)**/test/**' ':(glob)**/tests/**' ':(glob)**/spec/**' ':(glob)**/__tests__/**' \
    ':(glob)**/*.test.*' ':(glob)**/*.spec.*' ':(glob)**/*_test.*' ':(glob)**/test_*.*' \
    ':(glob)**/*Test.*' ':(glob)**/*Tests.*' ':(glob)**/*.bats' \
    ':(exclude)openspec/**' ':(exclude).specify/**' ':(exclude)specs/**' 2>/dev/null || true)
  TEST_EPOCH=${TEST_EPOCH:-0}
fi

DIR=$(changes_dir "$ROOT")
reported=0
TAB=$(printf '\t')
for line in $(list_changes "$DIR" | awk -F "$TAB" '$2 == "active" { print $1 "|" $3 }'); do
  name=${line%%|*}; path=${line#*|}
  tf="$path/tasks.md"
  [ -f "$tf" ] || continue
  total=$(grep -c '^[[:space:]]*- \[[ xX]\]' "$tf" || true)
  done_n=$(grep -c '^[[:space:]]*- \[[xX]\]' "$tf" || true)
  [ "$total" -gt 0 ] || continue
  rel=${path#"$ROOT"/}
  msg=""
  if [ "$ARCHIVE_WHEN_DONE" = true ] && [ "$done_n" -eq "$total" ]; then
    msg="verify, then archive"
  fi
  codeless=0
  case "$name" in m[0-9]*-*|d[0-9]*-*) codeless=1 ;; esac   # milestones and docs changes ship no code
  if [ -z "$msg" ] && [ "$UNTESTED" = true ] && [ "$codeless" -eq 0 ] && [ "$done_n" -gt 0 ]; then
    if dirty "$rel/tasks.md"; then ticked=9999999999; else ticked=$(last_commit "$rel/tasks.md"); fi
    if [ "$ticked" -gt "$TEST_EPOCH" ]; then
      msg="tasks ticked since the last test change, add or run tests"
    fi
  fi
  if [ -z "$msg" ] && [ "$STALE_DAYS" -gt 0 ]; then
    t=$(last_commit "$rel")
    if [ "$t" -gt 0 ] && ! dirty "$rel"; then
      age=$((TODAY_DAYS - t / 86400))
      if [ "$age" -gt "$STALE_DAYS" ]; then msg="no commit for $age days, continue or close"; fi
    fi
  fi
  if [ -n "$msg" ]; then
    printf '%s  %s/%s tasks → %s\n' "$name" "$done_n" "$total" "$msg"
    reported=$((reported + 1))
  fi
done

[ "$reported" -gt 0 ] || echo "groma status: nothing open"
