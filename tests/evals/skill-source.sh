#!/bin/sh
# Skill-source check for the evals. Read-only. Claude Code loads user-level
# skills next to `--plugin-dir`, so a user-level groma skill that leads into
# another checkout would make an eval test that checkout's text instead.
#
# Usage: tests/evals/skill-source.sh <root>
#   <root>  the checkout under test (its skills/ folder)
# Reads:  $CLAUDE_CONFIG_DIR/skills when CLAUDE_CONFIG_DIR is set, else
#         $HOME/.claude/skills; every folder named groma or groma-* there.
# Env:    GROMA_EVAL_ALLOW_USER_SKILLS=1 turns a conflict into a warning.
# Output: nothing when every user-level groma skill resolves (symlinks
#         followed) to <root>/skills/<same name>; otherwise one stderr line per
#         conflict, `skill-source: <path> resolves to <real>, not <expected>`,
#         and one line with the fix.
# Exit:   0 ok or allowed, 3 conflict, 2 usage error.
set -eu

[ $# -eq 1 ] || { echo "usage: skill-source.sh <root>" >&2; exit 2; }
[ -d "$1" ] || { echo "not a folder: $1" >&2; exit 2; }
ROOT=$(CDPATH='' cd -P -- "$1" && pwd -P)
if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
  SKILLS="${CLAUDE_CONFIG_DIR%/}/skills"
else
  SKILLS="$HOME/.claude/skills"
fi
[ -d "$SKILLS" ] || exit 0

conflicts=0
for d in "$SKILLS"/groma "$SKILLS"/groma-*; do
  # a missing glob match, a broken link or a file is no skill Claude Code loads
  [ -d "$d" ] || continue
  name=${d##*/}
  real=$(CDPATH='' cd -P -- "$d" && pwd -P)
  expected="$ROOT/skills/$name"
  if [ -d "$expected" ]; then
    expected=$(CDPATH='' cd -P -- "$expected" && pwd -P)
  fi
  [ "$real" = "$expected" ] && continue
  echo "skill-source: $d resolves to $real, not $expected" >&2
  conflicts=$((conflicts + 1))
done
[ "$conflicts" -eq 0 ] && exit 0

if [ "${GROMA_EVAL_ALLOW_USER_SKILLS:-}" = 1 ]; then
  echo "skill-source: warning: $conflicts user-level groma skill(s) may shadow $ROOT/skills; continuing because GROMA_EVAL_ALLOW_USER_SKILLS=1" >&2
  exit 0
fi
echo "skill-source: fix: remove or relink each path above to $ROOT/skills/<name>, run the evals from the checkout it points to, or set GROMA_EVAL_ALLOW_USER_SKILLS=1 to run anyway" >&2
exit 3
