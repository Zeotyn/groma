#!/bin/sh
# Level 4: headless agent evals. Runs /groma with scripted answers on fresh
# copies of the fixtures and asserts the results. Costs API tokens.
#
# Usage: tests/evals/run.sh [fixture...]      (default: all fixtures)
#        cli-<fixture>: run `groma init --yes --print` on <fixture> first, then /groma
#        conflict-<fixture>: start on the change branch with a conflicting commit on main
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
  set -- empty node-prisma java-flyway python-django-stale-docs go-no-db loop-openspec cli-node-prisma conflict-loop-openspec
fi

rm -rf "$WORK"
mkdir -p "$WORK"
for fx in "$@"; do
  case "$fx" in
    cli-*) sh "$ROOT/tests/fixtures/generate.sh" "$WORK/cli" "${fx#cli-}" >/dev/null
           mv "$WORK/cli/${fx#cli-}" "$WORK/$fx" ;;
    conflict-*)
      # the loop starts on the change branch; main then rewords the first task line,
      # so the loop's commit that ticks it conflicts when the branch is rebased
      sh "$ROOT/tests/fixtures/generate.sh" "$WORK/conflict" "${fx#conflict-}" >/dev/null
      mv "$WORK/conflict/${fx#conflict-}" "$WORK/$fx"
      P="$WORK/$fx"
      tasks=$(find "$P/openspec/changes" -mindepth 2 -maxdepth 2 -name tasks.md | head -n 1)
      branch=$(basename "$(dirname "$tasks")")
      git -C "$P" branch -q "$branch"
      awk '!done && /^- \[ \] / { $0 = $0 " (reworded on main)"; done = 1 } { print }' "$tasks" > "$tasks.new"
      mv "$tasks.new" "$tasks"
      git -C "$P" add -A
      GIT_AUTHOR_DATE="2026-10-03T12:00:00Z" GIT_COMMITTER_DATE="2026-10-03T12:00:00Z" \
        git -C "$P" commit -q -m "docs: reword the first task on main"
      git -C "$P" rev-parse main > "$WORK/$fx.main"
      git -C "$P" switch -q "$branch" ;;
    *) sh "$ROOT/tests/fixtures/generate.sh" "$WORK" "$fx" >/dev/null ;;
  esac
done

failed=0
for fx in "$@"; do
  P="$WORK/$fx"
  sh "$ROOT/tests/invariant/checksum.sh" snapshot "$P" "$WORK/$fx.manifest" >/dev/null
  case "$fx" in
    cli-*) node "$ROOT/bin/groma.js" init "$P" --yes --print --agents claude,copilot \
             --methodology openspec --skills recommended > "$WORK/$fx.cli.log" 2>&1 \
             || { echo "   FAIL $fx: groma init failed (see $WORK/$fx.cli.log)"; failed=$((failed + 1)); continue; } ;;
  esac
  tools="Bash(sh:*) Bash(grep:*) Bash(find:*) Bash(ls:*) Bash(cat:*) Bash(git log:*) Bash(git config:*) Bash(mkdir:*) Read Write Edit Glob Grep Skill Edit(.groma/**)"

  if [ -f "$HERE/prompts/$fx.md" ]; then
    # fixture with its own task (for example the review loop)
    prompt=$(cat "$HERE/prompts/$fx.md")
    tools="$tools Bash(node:*) Bash(npm test:*) Bash(openspec:*) Bash(git diff:*) Bash(git rev-parse:*) Bash(git status:*) Bash(git add:*) Bash(git commit:*) Bash(rm:*) Bash(claude:*)"
    # git steps of the loop: branch, integrate, abort; no push target exists in the fixtures
    tools="$tools Bash(git switch:*) Bash(git branch:*) Bash(git symbolic-ref:*) Bash(git merge-base:*) Bash(git rebase:*) Bash(git merge:*) Bash(git reset --merge:*) Bash(git remote:*) Bash(git push:*) Bash(git ls-files:*) Bash(git rev-list:*)"
  else
  answers="$HERE/answers/$fx.md"
  [ -f "$answers" ] || { echo "missing answers file: $answers" >&2; exit 2; }
  prompt="Run the groma skill (/groma) in the current directory.
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
