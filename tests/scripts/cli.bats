#!/usr/bin/env bats
# End-to-end tests for the groma CLI on generated fixtures, with stubbed
# npx, claude and openspec on PATH. Includes the never-overwrite invariant.

load helpers

GROMA="$ROOT/bin/groma.js"
CHECK="$ROOT/tests/invariant/checksum.sh"

setup() {
  command -v node >/dev/null 2>&1 || skip "node not installed"
  W="$BATS_TEST_TMPDIR"
  sh "$ROOT/tests/fixtures/generate.sh" "$W" node-prisma java-flyway >/dev/null
  STUBS="$W/stubs"
  LOG="$W/calls.log"
  mkdir -p "$STUBS"
  for c in npx claude openspec; do
    printf '#!/bin/sh\necho "%s $*" >> "%s"\nexit 0\n' "$c" "$LOG" > "$STUBS/$c"
    chmod +x "$STUBS/$c"
  done
  : > "$LOG"
  NODE_DIR=$(dirname "$(command -v node)")
  export PATH="$STUBS:$NODE_DIR:/usr/bin:/bin"
}

groma() { node "$GROMA" "$@"; }

@test "init --yes --print keeps every pre-existing file and runs nothing" {
  P="$W/node-prisma"
  sh "$CHECK" snapshot "$P" "$W/m" >/dev/null
  run groma init "$P" --agents claude,copilot --methodology openspec --skills recommended --yes --print
  [ "$status" -eq 0 ]
  run sh "$CHECK" verify "$P" "$W/m"
  [ "$status" -eq 0 ]
  run grep -v '^claude plugin list' "$LOG"
  [ "$status" -eq 1 ]
  grep -q 'generatedBy: groma@' "$P/.claude/skills/groma/SKILL.md"
  [ -f "$P/.github/skills/groma-survey/scripts/freshness.sh" ]
  grep -q '^project_type: brownfield' "$P/.groma/config.yaml"
  grep -q '^  skills: pending' "$P/.groma/config.yaml"
  grep -q 'openspec@1.16.0 init --tools claude,github-copilot' "$P/.groma/install.sh"
  grep -q 'claude plugin install superpowers@claude-plugins-official --scope project' "$P/.groma/install.sh"
  run sh "$ROOT/skills/groma/scripts/validate-config.sh" "$P/.groma/config.yaml" --catalog "$ROOT/skills/groma-skills/catalog.yaml"
  [ "$status" -eq 0 ]
}

@test "init runs the stubbed installers and keeps the invariant" {
  P="$W/java-flyway"
  sh "$CHECK" snapshot "$P" "$W/m" >/dev/null
  run groma init "$P" --agents copilot --methodology openspec --skills ponytail --yes
  [ "$status" -eq 0 ]
  run sh "$CHECK" verify "$P" "$W/m"
  [ "$status" -eq 0 ]
  grep -q 'npx --yes @fission-ai/openspec@1.16.0 init --tools github-copilot' "$LOG"
  grep -q 'npx --yes skills@1.7.6 add https://github.com/DietrichGebert/ponytail/tree/v5.3.3' "$LOG"
  grep -q '^  methodology: done' "$P/.groma/config.yaml"
  [ ! -f "$P/.groma/install.sh" ]
}

@test "an existing skills-lock.json is never handed to npx skills under --yes" {
  P="$W/node-prisma"
  echo '{}' > "$P/skills-lock.json"
  run groma init "$P" --agents copilot --methodology none --skills ponytail --yes
  [ "$status" -eq 0 ]
  run grep -q 'skills@' "$LOG"
  [ "$status" -eq 1 ]
  grep -q 'skills@1.7.6 add' "$P/.groma/install.sh"
  [ "$(cat "$P/skills-lock.json")" = '{}' ]
}

@test "--dry-run leaves the project byte-identical with no new files" {
  P="$W/node-prisma"
  before=$(cd "$P" && find . -path ./.git -prune -o -type f -print | sort)
  sh "$CHECK" snapshot "$P" "$W/m" >/dev/null
  run groma init "$P" --agents claude,copilot --yes --dry-run
  [ "$status" -eq 0 ]
  assert_output_contains ".claude/skills/groma/SKILL.md"
  run sh "$CHECK" verify "$P" "$W/m"
  [ "$status" -eq 0 ]
  [ "$(cd "$P" && find . -path ./.git -prune -o -type f -print | sort)" = "$before" ]
}

@test "update after init keeps the invariant and user edits" {
  P="$W/node-prisma"
  groma init "$P" --agents claude --methodology none --skills none --yes >/dev/null
  echo "my notes" >> "$P/.claude/skills/groma-survey/SKILL.md"
  sh "$CHECK" snapshot "$P" "$W/m" >/dev/null
  run groma update "$P" --yes
  [ "$status" -eq 0 ]
  assert_output_contains "edited, not updated"
  run sh "$CHECK" verify "$P" "$W/m"
  [ "$status" -eq 0 ]
}

@test "doctor and status run on an initialized fixture" {
  P="$W/java-flyway"
  groma init "$P" --agents copilot --methodology none --skills none --yes >/dev/null
  run groma status "$P"
  [ "$status" -eq 0 ]
  run groma doctor "$P"
  assert_output_contains "config: ok"
  assert_output_contains "generated files: ok"
}
