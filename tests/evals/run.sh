#!/bin/sh
# Level 4: headless agent evals. Runs /groma with scripted answers on fresh
# copies of the fixtures and asserts the results. Costs API tokens.
#
# Usage: tests/evals/run.sh [fixture...]      (default: all fixtures)
# Env:   GROMA_EVAL_BUDGET  max USD per fixture run (default 3)
#        GROMA_EVAL_DIR     work folder (default: $TMPDIR/groma-evals)
#        GROMA_EVAL_MODEL   model alias for claude -p (default: CLI default)
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH='' cd -- "$HERE/../.." && pwd)
# Outside the repo and without dot-folders in the path: headless permission
# checks treat writes below hidden folders such as tests/.work as sensitive.
WORK=${GROMA_EVAL_DIR:-"${TMPDIR:-/tmp}/groma-evals"}
WORK=${WORK%/}
BUDGET=${GROMA_EVAL_BUDGET:-3}
command -v claude >/dev/null 2>&1 || { echo "claude CLI not found" >&2; exit 3; }

if [ $# -eq 0 ]; then
  set -- empty node-prisma java-flyway python-django-stale-docs go-no-db loop-openspec
fi

rm -rf "$WORK"
mkdir -p "$WORK"
sh "$ROOT/tests/fixtures/generate.sh" "$WORK" "$@" >/dev/null

failed=0
for fx in "$@"; do
  P="$WORK/$fx"
  sh "$ROOT/tests/invariant/checksum.sh" snapshot "$P" "$WORK/$fx.manifest" >/dev/null
  tools="Bash(sh:*) Bash(grep:*) Bash(find:*) Bash(ls:*) Bash(cat:*) Bash(git log:*) Bash(git config:*) Bash(mkdir:*) Read Write Edit Glob Grep Skill Edit(.groma/**)"

  if [ -f "$HERE/prompts/$fx.md" ]; then
    # fixture with its own task (for example the review loop)
    prompt=$(cat "$HERE/prompts/$fx.md")
    tools="$tools Bash(node:*) Bash(npm test:*) Bash(openspec:*) Bash(git diff:*) Bash(git rev-parse:*) Bash(git status:*) Bash(git add:*) Bash(git commit:*) Bash(rm:*) Bash(claude:*)"
  else
  answers="$HERE/answers/$fx.md"
  [ -f "$answers" ] || { echo "missing answers file: $answers" >&2; exit 2; }
  prompt="Run the groma skill (/groma) in the current directory, in init mode.
This is an automated evaluation: nobody can answer questions. Use the answers
below whenever groma would ask; for anything not covered, take groma's
recommended default.
Do not install third-party skills, plugins or methodologies and do not use the
network: write every install command to .groma/install.sh instead and mark the
step pending. Today is 2026-11-04.

$(cat "$answers")"
  fi

  echo "== eval $fx"
  set +e
  # shellcheck disable=SC2086
  (cd "$P" && claude -p "$prompt" \
      --plugin-dir "$ROOT" \
      --permission-mode acceptEdits \
      --allowedTools "$tools" \
      --max-budget-usd "$BUDGET" \
      ${GROMA_EVAL_MODEL:+--model "$GROMA_EVAL_MODEL"} \
      --output-format text > "$WORK/$fx.log" 2>&1)
  rc=$?
  set -e
  [ "$rc" -eq 0 ] || echo "   claude exited $rc (see $WORK/$fx.log)"

  if sh "$HERE/assert.sh" "$fx" "$P" "$WORK/$fx.manifest"; then
    echo "   PASS $fx"
  else
    echo "   FAIL $fx (log: $WORK/$fx.log)"
    failed=$((failed + 1))
  fi
done

echo "evals: $(($# - failed)) passed, $failed failed"
[ "$failed" -eq 0 ]
