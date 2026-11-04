#!/bin/sh
# Run groma's test suite.
#   scripts/test.sh            levels 1-3: structure, script tests, invariant
#   scripts/test.sh structure  level 1 only
#   scripts/test.sh scripts    level 2+3 only (bats)
#   scripts/test.sh evals      level 4: headless agent evals (costs tokens)
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

PYYAML="pyyaml==6.0.2"
PYTEST="pytest==8.3.3"
BATS_VERSION="1.13.0"

run_structure() {
  echo "== level 1: structure"
  uv run --quiet --no-project --with "$PYYAML" --with "$PYTEST" \
    python -m pytest -q tests/structure
  uv run --quiet --no-project --with "$PYYAML" python tests/structure/check.py all
  if command -v shellcheck >/dev/null 2>&1; then
    # shellcheck disable=SC2046
    shellcheck -x -s sh $(find scripts skills tests -name '*.sh' -not -path '*/.work/*') \
      $(ls install.sh uninstall.sh 2>/dev/null || true)
    echo "[shellcheck] ok"
  else
    echo "[shellcheck] skipped (not installed)"
  fi
}

bats_cmd() {
  if command -v bats >/dev/null 2>&1; then
    bats "$@"
  else
    npx --yes "bats@$BATS_VERSION" "$@"
  fi
}

run_scripts() {
  echo "== level 2+3: script tests and invariant"
  bats_cmd -r tests/scripts tests/invariant
}

run_evals() {
  echo "== level 4: evals"
  sh tests/evals/run.sh "$@"
}

case "${1:-all}" in
  structure) run_structure ;;
  scripts) run_scripts ;;
  evals) shift; run_evals "$@" ;;
  all) run_structure; run_scripts ;;
  *) echo "usage: $0 [structure|scripts|evals|all]" >&2; exit 2 ;;
esac
