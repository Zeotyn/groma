#!/usr/bin/env bats
# skill-source.sh stops an eval run when a user-level groma skill would shadow
# the checkout under test. Every test uses a temporary HOME and
# CLAUDE_CONFIG_DIR; none calls claude.

load helpers

S="$ROOT/tests/evals/skill-source.sh"

setup() {
  # resolved, because the script prints resolved paths (/tmp is /private/tmp on macOS)
  T=$(cd -P "$BATS_TEST_TMPDIR" && pwd -P)
  # the checkout under test and another checkout, each with two groma skills
  for c in checkout other; do
    mkdir -p "$T/$c/skills/groma" "$T/$c/skills/groma-loop"
  done
  mkdir -p "$T/home"
  export HOME="$T/home"
  unset CLAUDE_CONFIG_DIR GROMA_EVAL_ALLOW_USER_SKILLS
  USER_SKILLS="$HOME/.claude/skills"
}

@test "no user skills folder passes silently" {
  run sh "$S" "$T/checkout"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "symlinks into the checkout under test pass" {
  mkdir -p "$USER_SKILLS"
  ln -s "$T/checkout/skills/groma" "$USER_SKILLS/groma"
  ln -s "$T/checkout/skills/groma-loop" "$USER_SKILLS/groma-loop"
  run sh "$S" "$T/checkout"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a root given through a symlink still matches" {
  mkdir -p "$USER_SKILLS"
  ln -s "$T/checkout/skills/groma" "$USER_SKILLS/groma"
  ln -s "$T/checkout" "$T/link"
  run sh "$S" "$T/link"
  [ "$status" -eq 0 ]
}

@test "symlink into another checkout exits 3 with path and fix" {
  mkdir -p "$USER_SKILLS"
  ln -s "$T/checkout/skills/groma" "$USER_SKILLS/groma"
  ln -s "$T/other/skills/groma-loop" "$USER_SKILLS/groma-loop"
  run sh "$S" "$T/checkout"
  [ "$status" -eq 3 ]
  assert_output_contains "$USER_SKILLS/groma-loop"
  assert_output_contains "$T/other/skills/groma-loop"
  assert_output_contains "GROMA_EVAL_ALLOW_USER_SKILLS=1"
  assert_output_not_contains "$USER_SKILLS/groma "
}

@test "a real folder is foreign and exits 3" {
  mkdir -p "$USER_SKILLS/groma"
  run sh "$S" "$T/checkout"
  [ "$status" -eq 3 ]
  assert_output_contains "$USER_SKILLS/groma"
}

@test "a user skill the checkout does not ship exits 3" {
  mkdir -p "$USER_SKILLS"
  ln -s "$T/other/skills/groma" "$USER_SKILLS/groma-old"
  run sh "$S" "$T/checkout"
  [ "$status" -eq 3 ]
  assert_output_contains "$USER_SKILLS/groma-old"
}

@test "GROMA_EVAL_ALLOW_USER_SKILLS=1 warns and exits 0" {
  mkdir -p "$USER_SKILLS"
  ln -s "$T/other/skills/groma" "$USER_SKILLS/groma"
  GROMA_EVAL_ALLOW_USER_SKILLS=1 run sh "$S" "$T/checkout"
  [ "$status" -eq 0 ]
  assert_output_contains "warning"
  assert_output_contains "$USER_SKILLS/groma"
}

@test "skills not named groma are ignored" {
  mkdir -p "$USER_SKILLS/graphify" "$USER_SKILLS/gromax"
  ln -s "$T/other/skills/groma" "$USER_SKILLS/my-groma"
  run sh "$S" "$T/checkout"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "CLAUDE_CONFIG_DIR wins over HOME" {
  mkdir -p "$USER_SKILLS" "$T/config/skills"
  ln -s "$T/other/skills/groma" "$USER_SKILLS/groma"
  ln -s "$T/checkout/skills/groma" "$T/config/skills/groma"
  CLAUDE_CONFIG_DIR="$T/config" run sh "$S" "$T/checkout"
  [ "$status" -eq 0 ]
  ln -s "$T/other/skills/groma-loop" "$T/config/skills/groma-loop"
  CLAUDE_CONFIG_DIR="$T/config" run sh "$S" "$T/checkout"
  [ "$status" -eq 3 ]
  assert_output_contains "$T/config/skills/groma-loop"
}

@test "run.sh stops with exit 3 before claude is called" {
  mkdir -p "$T/bin" "$T/config/skills"
  # the stub records a call; it must never run
  printf '#!/bin/sh\ntouch "%s"\n' "$T/claude-called" > "$T/bin/claude"
  chmod +x "$T/bin/claude"
  ln -s "$T/other/skills/groma" "$T/config/skills/groma"
  PATH="$T/bin:$PATH" CLAUDE_CONFIG_DIR="$T/config" GROMA_EVAL_DIR="$T/work" \
    GROMA_EVAL_REPORTS="$T/reports" run sh "$ROOT/tests/evals/run.sh" empty
  [ "$status" -eq 3 ]
  assert_output_contains "$T/config/skills/groma"
  [ ! -e "$T/claude-called" ]
  [ ! -e "$T/work" ]
  [ ! -e "$T/reports" ]
}

@test "missing root is a usage error" {
  run sh "$S"
  [ "$status" -eq 2 ]
  run sh "$S" "$T/nope"
  [ "$status" -eq 2 ]
}
