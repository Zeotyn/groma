#!/usr/bin/env bats

load helpers

setup() {
  H="$BATS_TEST_TMPDIR/home"
  mkdir -p "$H/.claude" "$H/.copilot"
}

inst() { sh "$ROOT/install.sh" --source "$ROOT" --home "$H" "$@"; }

@test "links all skills into detected agents only" {
  run inst
  [ "$status" -eq 0 ]
  [ -L "$H/.claude/skills/groma" ]
  [ -L "$H/.copilot/skills/groma-survey" ]
  [ ! -e "$H/.gemini" ]
  [ "$(readlink "$H/.claude/skills/groma")" = "$ROOT/skills/groma" ]
}

@test "second run reports already installed and changes nothing" {
  inst >/dev/null
  run inst
  [ "$status" -eq 0 ]
  assert_output_contains "linked 0, copied 0, already installed 14, conflicts 0"
}

@test "foreign skill with same name is a conflict, kept, exit non-zero" {
  mkdir -p "$H/.claude/skills/groma" && echo mine > "$H/.claude/skills/groma/SKILL.md"
  run inst
  [ "$status" -ne 0 ]
  assert_output_contains "CONFLICT claude"
  [ "$(cat "$H/.claude/skills/groma/SKILL.md")" = "mine" ]
}

@test "dry-run changes nothing" {
  run inst --dry-run
  [ "$status" -eq 0 ]
  assert_output_contains "dry-run: ln -s"
  [ ! -e "$H/.claude/skills" ]
}

@test "copy mode writes marker and can be re-run" {
  run inst --copy --agents claude
  [ -f "$H/.claude/skills/groma/SKILL.md" ]
  [ -f "$H/.claude/skills/groma/.groma-installed" ]
  run inst --copy --agents claude
  [ "$status" -eq 0 ]
  assert_output_contains "updated  claude: groma (copy)"
}

@test "uninstall removes only groma-created entries" {
  inst >/dev/null
  mkdir -p "$H/.claude/skills/other" && echo x > "$H/.claude/skills/other/SKILL.md"
  run sh "$ROOT/uninstall.sh" --source "$ROOT" --home "$H"
  [ "$status" -eq 0 ]
  [ ! -e "$H/.claude/skills/groma" ]
  [ -f "$H/.claude/skills/other/SKILL.md" ]
}

@test "uninstall keeps a foreign skill named like ours" {
  mkdir -p "$H/.claude/skills/groma" && echo mine > "$H/.claude/skills/groma/SKILL.md"
  run sh "$ROOT/uninstall.sh" --source "$ROOT" --home "$H" --agents claude
  assert_output_contains "kept     claude: groma (not installed by groma)"
  [ -f "$H/.claude/skills/groma/SKILL.md" ]
}

@test "no agents detected fails with hint" {
  run sh "$ROOT/install.sh" --source "$ROOT" --home "$BATS_TEST_TMPDIR/empty-home"
  [ "$status" -eq 1 ]
  assert_output_contains "Use --agents"
}

@test "unknown agent fails" {
  run inst --agents vim
  [ "$status" -eq 2 ]
}
