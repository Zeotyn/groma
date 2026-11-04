#!/bin/sh
# Run groma's test suite.
#   scripts/test.sh            levels 1-3: structure, CLI, script tests, invariant
#   scripts/test.sh structure  level 1 only
#   scripts/test.sh scripts    level 2+3 only (bats)
#   scripts/test.sh cli        CLI unit tests (node --test) and package contents
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

run_cli() {
  echo "== cli: unit tests and package contents"
  [ -d node_modules ] || npm ci --silent
  node --test 'cli/test/*.test.js'
  npm pack --dry-run --json --silent | node -e '
    let s = ""; process.stdin.on("data", d => s += d).on("end", () => {
      const files = JSON.parse(s)[0].files.map(f => f.path);
      const need = ["bin/groma.js", "cli/main.js", "package.json", "skills/groma/SKILL.md", "skills/groma/VERSION",
        "skills/groma/agents.yaml", "skills/groma/templates/config.yaml", "skills/groma-skills/catalog.yaml",
        "skills/groma-methodology/methodologies.yaml"];
      const bad = need.filter(f => !files.includes(f))
        .concat(files.filter(f => /^(tests|openspec|scripts|docs|cli\/test)\//.test(f)));
      if (bad.length) { console.error("package contents wrong:", bad.join(", ")); process.exit(1); }
      console.log("[pack] ok (" + files.length + " files)");
    });'
}

run_evals() {
  echo "== level 4: evals"
  sh tests/evals/run.sh "$@"
}

case "${1:-all}" in
  structure) run_structure ;;
  scripts) run_scripts ;;
  cli) run_cli ;;
  evals) shift; run_evals "$@" ;;
  all) run_structure; run_cli; run_scripts ;;
  *) echo "usage: $0 [structure|scripts|cli|evals|all]" >&2; exit 2 ;;
esac
