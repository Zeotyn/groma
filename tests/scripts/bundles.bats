#!/usr/bin/env bats
# Claude Code marketplace bundles (ADR 0050): each entry of
# .claude-plugin/marketplace.json installs exactly its skills. The marketplace
# is added from a copy of this checkout into an isolated CLAUDE_CONFIG_DIR
# under the test's temp dir, so the user's own Claude configuration is never
# touched. No login is needed and no model is called. Skipped when `claude` is
# not on PATH, except in CI (`CI` set), where .github/workflows/test.yml
# installs Claude Code and a missing `claude` fails.

load helpers

setup() {
  if ! command -v claude >/dev/null 2>&1; then
    [ -z "${CI:-}" ] || { echo "claude not installed; CI must install Claude Code"; return 1; }
    skip "claude not installed"
  fi
  T="$BATS_TEST_TMPDIR"
  mkdir -p "$T/repo"
  cp -R "$ROOT/.claude-plugin" "$ROOT/skills" "$T/repo/"
  export CLAUDE_CONFIG_DIR="$T/cfg"
  export DISABLE_AUTOUPDATER=1
  export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
  cd "$T"
  claude plugin marketplace add ./repo >/dev/null
}

# skills_of <bundle>: the skill names `claude plugin details` lists, one per line
skills_of() {
  claude plugin install "$1@groma" >/dev/null
  claude plugin details "$1@groma" | sed -n 's/^ *Skills ([0-9]*) *//p' | tr -s ', ' '\n\n' | sed '/^$/d' | sort
}

@test "the marketplace validates" {
  run claude plugin validate ./repo
  [ "$status" -eq 0 ]
  assert_output_contains "Validation passed"
}

@test "groma installs every skill" {
  run skills_of groma
  [ "$status" -eq 0 ]
  [ "$output" = "$(ls "$ROOT/skills" | sort)" ]
}

@test "groma-docs installs only detect, survey and lay-out" {
  run skills_of groma-docs
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf 'groma-detect\ngroma-lay-out\ngroma-survey')" ]
}

@test "groma-loop installs only groma-loop" {
  run skills_of groma-loop
  [ "$status" -eq 0 ]
  [ "$output" = "groma-loop" ]
}

@test "every bundle carries the full plugin's version" {
  v=$(cat "$ROOT/skills/groma/VERSION")
  for b in groma groma-docs groma-loop; do
    claude plugin install "$b@groma" >/dev/null
    run claude plugin details "$b@groma"
    [ "$status" -eq 0 ]
    assert_output_contains "groma $v"
  done
}
