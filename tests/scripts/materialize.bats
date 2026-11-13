#!/usr/bin/env bats
# materialize.sh: the agent-side copy of the groma skills. The scenarios are
# those of cli/test/skills.test.js; the parity tests run the same project
# through the CLI and compare the results byte for byte.

load helpers

M="$ROOT/skills/groma/scripts/materialize.sh"
GROMA="$ROOT/bin/groma.js"

setup() {
  W="$BATS_TEST_TMPDIR"
  P="$W/project"
  mkdir -p "$P" "$W/stubs"
  VERSION=$(tr -d '\n' < "$ROOT/skills/groma/VERSION")
  # no real `claude` on PATH: the plugin check must never reach the user's installation
  TOOLS="$W/stubs:/usr/bin:/bin:/sbin"
  if command -v node >/dev/null 2>&1; then TOOLS="$W/stubs:$(dirname "$(command -v node)"):/usr/bin:/bin:/sbin"; fi
  export PATH="$TOOLS"
}

sha() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -c1-64; else shasum -a 256 "$1" | cut -c1-64; fi
}

# record <path> <text>: point the record of <path> at the hash of <text>
record() {
  h=$(printf '%s' "$2" | { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi; } | cut -c1-64)
  if grep -qF "\"$1\"" "$P/.groma/generated.json"; then
    sed "s|\"$1\": \"[0-9a-f]*\"|\"$1\": \"$h\"|" "$P/.groma/generated.json" > "$W/gen" && cat "$W/gen" > "$P/.groma/generated.json"
  else
    sed "s|^  \"files\": {\$|  \"files\": {\\
    \"$1\": \"$h\",|" "$P/.groma/generated.json" > "$W/gen" && cat "$W/gen" > "$P/.groma/generated.json"
  fi
}

stub_claude() { # <plugin list output>
  printf '#!/bin/sh\necho "claude $*" >> "%s"\n[ "$1 $2" = "plugin list" ] && printf "%%s\\n" "%s"\nexit 0\n' "$W/calls.log" "$1" > "$W/stubs/claude"
  chmod +x "$W/stubs/claude"
}

@test "usage errors exit 2" {
  run sh "$M"
  [ "$status" -eq 2 ]
  run sh "$M" "$P"
  [ "$status" -eq 2 ]
  assert_output_contains "--agents is required"
  run sh "$M" --agents nope "$P"
  [ "$status" -eq 2 ]
  assert_output_contains "unknown agent: nope"
  run sh "$M" --agents claude "$W/missing"
  [ "$status" -eq 2 ]
  run sh "$M" --bogus --agents claude "$P"
  [ "$status" -eq 2 ]
}

@test "create: every skill for claude and copilot, generatedBy and hashes" {
  run sh "$M" --agents claude,copilot "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "create	.claude/skills/groma/SKILL.md"
  for d in .claude/skills .github/skills; do
    for s in "$ROOT"/skills/*/; do
      [ -f "$P/$d/$(basename "$s")/SKILL.md" ]
    done
    grep -q "^  generatedBy: groma@$VERSION\$" "$P/$d/groma/SKILL.md"
  done
  cmp "$ROOT/skills/groma-detect/scripts/detect.sh" "$P/.claude/skills/groma-detect/scripts/detect.sh"
  grep -q "\"generatedBy\": \"groma@$VERSION\"" "$P/.groma/generated.json"
  # every copied file is recorded with its hash, and nothing else
  n=$(find "$P/.claude" "$P/.github" -type f | wc -l | tr -d ' ')
  [ "$(grep -c '^    "' "$P/.groma/generated.json")" -eq "$n" ]
  for f in .github/skills/groma-detect/scripts/detect.sh .claude/skills/groma/SKILL.md; do
    grep -qF "\"$f\": \"$(sha "$P/$f")\"" "$P/.groma/generated.json"
  done
  # sorted keys
  grep '^    "' "$P/.groma/generated.json" | cut -d'"' -f2 > "$W/keys"
  LC_ALL=C sort -c "$W/keys"
  [ "$(printf '%s\n' "$output" | tail -1)" = "summary	created=$n	updated=0	removed=0	edited=0	conflicts=0	agents=claude,copilot	version=$VERSION	dry_run=0" ]
}

@test "generatedBy goes below an existing metadata key and files keep their mode" {
  S="$W/suite/skills"
  mkdir -p "$S/groma/scripts" "$S/groma-x/scripts" "$S/other" "$S/groma-nothing"
  cp "$M" "$S/groma/scripts/"
  cp "$ROOT/skills/groma/agents.yaml" "$S/groma/"
  echo 9.9.9 > "$S/groma/VERSION"
  printf -- '---\nname: groma\n---\nbody\n' > "$S/groma/SKILL.md"
  printf -- '---\nname: groma-x\nmetadata:\n  a: b\n---\n# x' > "$S/groma-x/SKILL.md"
  printf '#!/bin/sh\n' > "$S/groma-x/scripts/run.sh"
  chmod 755 "$S/groma-x/scripts/run.sh"
  echo x > "$S/other/SKILL.md"
  run sh "$S/groma/scripts/materialize.sh" --agents codex "$P"
  [ "$status" -eq 0 ]
  [ "$(cat "$P/.agents/skills/groma/SKILL.md")" = "$(printf -- '---\nname: groma\nmetadata:\n  generatedBy: groma@9.9.9\n---\nbody')" ]
  printf -- '---\nname: groma-x\nmetadata:\n  generatedBy: groma@9.9.9\n  a: b\n---\n# x' > "$W/want"
  cmp "$W/want" "$P/.agents/skills/groma-x/SKILL.md"
  [ -x "$P/.agents/skills/groma-x/scripts/run.sh" ]
  [ ! -x "$P/.agents/skills/groma-x/SKILL.md" ]
  # only groma skill folders next to the script are copied
  [ ! -e "$P/.agents/skills/other" ]
  [ ! -e "$P/.agents/skills/groma-nothing" ]

  # a copy of a copy carries one generatedBy line
  mkdir "$W/second"
  run sh "$P/.agents/skills/groma/scripts/materialize.sh" --agents claude "$W/second"
  [ "$status" -eq 0 ]
  cmp "$P/.agents/skills/groma-x/SKILL.md" "$W/second/.claude/skills/groma-x/SKILL.md"
  [ "$(grep -c generatedBy "$W/second/.claude/skills/groma/SKILL.md")" -eq 1 ]
}

@test "--skills copies only the listed skill folders" {
  run sh "$M" --agents claude --skills groma-detect,groma-survey "$P"
  [ "$status" -eq 0 ]
  [ "$(ls "$P/.claude/skills" | tr '\n' ' ')" = "groma-detect groma-survey " ]
}

@test "--dry-run prints the plan and writes nothing" {
  run sh "$M" --dry-run --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "create	.claude/skills/groma/SKILL.md"
  assert_output_contains "dry_run=1"
  [ -z "$(ls -A "$P")" ]
}

@test "a foreign skill folder is a conflict and stays untouched" {
  mkdir -p "$P/.claude/skills/groma-survey"
  printf 'mine' > "$P/.claude/skills/groma-survey/SKILL.md"
  run sh "$M" --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "conflict	.claude/skills/groma-survey"
  assert_output_contains "conflicts=1"
  [ "$(cat "$P/.claude/skills/groma-survey/SKILL.md")" = mine ]
  [ "$(ls "$P/.claude/skills/groma-survey")" = SKILL.md ]
  [ -f "$P/.claude/skills/groma-detect/SKILL.md" ]
  run grep -c groma-survey "$P/.groma/generated.json"
  [ "$output" = 0 ]
}

@test "an existing file without a record inside a generated folder is a conflict" {
  sh "$M" --agents claude "$P" >/dev/null
  rm "$P/.claude/skills/groma-detect/SKILL.md"
  sed '/groma-detect\/SKILL.md/d' "$P/.groma/generated.json" > "$W/gen" && cat "$W/gen" > "$P/.groma/generated.json"
  printf 'mine' > "$P/.claude/skills/groma-detect/SKILL.md"
  run sh "$M" --update --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "conflict	.claude/skills/groma-detect/SKILL.md"
  [ "$(cat "$P/.claude/skills/groma-detect/SKILL.md")" = mine ]
  run grep -c 'groma-detect/SKILL.md' "$P/.groma/generated.json"
  [ "$output" = 0 ]
}

@test "--update replaces unchanged old copies, keeps edited ones, --force replaces them" {
  sh "$M" --agents claude "$P" >/dev/null
  old=.claude/skills/groma-detect/SKILL.md
  edited=.claude/skills/groma-survey/SKILL.md
  original=$(sha "$P/$edited")
  printf 'old version' > "$P/$old"
  record "$old" 'old version'
  printf 'my edit' > "$P/$edited"

  run sh "$M" --update --dry-run --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "update	$old"
  [ "$(cat "$P/$old")" = 'old version' ]

  run sh "$M" --update --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "update	$old"
  assert_output_contains "edited	$edited"
  assert_output_contains "created=0	updated=1	removed=0	edited=1	conflicts=0"
  grep -q generatedBy "$P/$old"
  [ "$(cat "$P/$edited")" = 'my edit' ]
  # the record keeps the original hash so the edit stays visible
  grep -qF "\"$edited\": \"$original\"" "$P/.groma/generated.json"
  grep -qF "\"$old\": \"$(sha "$P/$old")\"" "$P/.groma/generated.json"

  run sh "$M" --update --force --agents claude "$P"
  [ "$status" -eq 0 ]
  grep -q generatedBy "$P/$edited"
  assert_output_contains "updated=1	removed=0	edited=0"
}

@test "files of removed skills are deleted only when unchanged" {
  sh "$M" --agents claude "$P" >/dev/null
  mkdir -p "$P/.claude/skills/groma-old/sub" "$P/.claude/skills/groma-gone/sub"
  printf 'old' > "$P/.claude/skills/groma-old/SKILL.md"
  printf 'edited' > "$P/.claude/skills/groma-old/notes.md"
  printf 'old' > "$P/.claude/skills/groma-gone/sub/a.md"
  record .claude/skills/groma-old/SKILL.md 'old'
  record .claude/skills/groma-old/notes.md 'original'
  record .claude/skills/groma-gone/sub/a.md 'old'
  run sh "$M" --update --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "remove	.claude/skills/groma-old/SKILL.md"
  assert_output_contains "edited	.claude/skills/groma-old/notes.md"
  assert_output_contains "removed=2	edited=1"
  [ ! -e "$P/.claude/skills/groma-old/SKILL.md" ]
  [ -f "$P/.claude/skills/groma-old/notes.md" ]
  # folders the removal left empty go too, the skills folder stays
  [ ! -e "$P/.claude/skills/groma-gone" ]
  [ -d "$P/.claude/skills" ]
  grep -q 'groma-old/notes.md' "$P/.groma/generated.json"
  run grep -c 'groma-old/SKILL.md\|groma-gone' "$P/.groma/generated.json"
  [ "$output" = 0 ]
}

@test "an unchanged copy needs no write; a file already holding the new content is not edited" {
  sh "$M" --agents claude "$P" >/dev/null
  cp "$P/.groma/generated.json" "$W/before"
  run sh "$M" --update --agents claude "$P"
  [ "$output" = "summary	created=0	updated=0	removed=0	edited=0	conflicts=0	agents=claude	version=$VERSION	dry_run=0" ]
  cmp "$W/before" "$P/.groma/generated.json"
  record .claude/skills/groma/SKILL.md 'stale record'
  run sh "$M" --update --agents claude "$P"
  assert_output_contains "edited=0"
  cmp "$W/before" "$P/.groma/generated.json"
}

@test "deselected agents and records outside groma skill folders are kept" {
  sh "$M" --agents claude,copilot "$P" >/dev/null
  echo '{}' > "$P/package.json"
  mkdir -p "$P/.claude/skills/other"
  printf 'x' > "$P/.claude/skills/other/SKILL.md"
  record package.json '{}
'
  record .claude/skills/other/SKILL.md 'x'
  record .claude/skills/groma/../../../package.json '{}
'
  run sh "$M" --update --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "removed=0"
  [ -f "$P/package.json" ]
  [ -f "$P/.claude/skills/other/SKILL.md" ]
  [ -f "$P/.github/skills/groma/SKILL.md" ]
  grep -q '".github/skills/groma/SKILL.md"' "$P/.groma/generated.json"
  grep -q '"package.json"' "$P/.groma/generated.json"
  grep -q '".claude/skills/other/SKILL.md"' "$P/.groma/generated.json"
}

@test "--update without --agents reads the config and leaves agents_via_plugin alone" {
  mkdir -p "$P/.groma"
  printf 'schema: 1\nagents: [claude, copilot]  # comment\nagents_via_plugin: [claude]\n' > "$P/.groma/config.yaml"
  run sh "$M" --update "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "agents=copilot"
  [ -f "$P/.github/skills/groma/SKILL.md" ]
  [ ! -e "$P/.claude" ]
  printf 'schema: 1\nagents:\n  - codex\n  - copilot\nskills:\n  design: none\n' > "$P/.groma/config.yaml"
  run sh "$M" --update --dry-run "$P"
  assert_output_contains "agents=codex,copilot"
  rm "$P/.groma/config.yaml"
  run sh "$M" --update "$P"
  [ "$status" -eq 2 ]
}

@test "a compact generated.json is read like a pretty one" {
  sh "$M" --agents claude "$P" >/dev/null
  cp "$P/.groma/generated.json" "$W/pretty"
  tr -d '\n ' < "$W/pretty" > "$P/.groma/generated.json"
  run sh "$M" --update --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "created=0	updated=0	removed=0	edited=0	conflicts=0"
  cmp "$W/pretty" "$P/.groma/generated.json"
  echo 'not json' > "$P/.groma/generated.json"
  run sh "$M" --update --agents claude "$P"
  [ "$status" -eq 1 ]
}

@test "plugin present: still copies, prints the disable command, never runs it" {
  stub_claude '  ❯ groma@groma'
  run sh "$M" --agents claude,copilot "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "plugin	claude	claude plugin disable groma@groma --scope local"
  [ -f "$P/.claude/skills/groma/SKILL.md" ]
  [ "$(cat "$W/calls.log")" = "claude plugin list" ]
  [ ! -e "$P/.claude/settings.local.json" ]
  [ ! -e "$P/.claude/settings.json" ]
  # no hint without claude among the agents, and none without the plugin
  run sh "$M" --update --agents copilot "$P"
  assert_output_not_contains "plugin	"
  stub_claude '  ❯ other@market'
  run sh "$M" --update --agents claude "$P"
  assert_output_not_contains "plugin	"
}

@test "run from a plugin folder: the hint needs no claude call" {
  S="$W/home/plugins/cache/groma/groma/1.0.0/skills"
  mkdir -p "$S"
  cp -R "$ROOT/skills/groma" "$ROOT/skills/groma-detect" "$S/"
  run sh "$S/groma/scripts/materialize.sh" --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "plugin	claude	claude plugin disable groma@groma --scope local"
  [ -f "$P/.claude/skills/groma-detect/SKILL.md" ]
  [ ! -e "$P/.claude/skills/groma-survey" ]
}

# --- parity with the CLI -------------------------------------------------------

# listing of a project: generated.json, every copied file with content hash and x bit
listing() {
  (cd "$1" && cat .groma/generated.json && find .claude .github -type f | LC_ALL=C sort | while IFS= read -r f; do
    if [ -x "$f" ]; then x=x; else x=-; fi
    printf '%s %s %s\n' "$(sha "$f")" "$x" "$f"
  done)
}

same_result() { # <cli project> <script project>
  diff -r "$1/.claude" "$2/.claude"
  diff -r "$1/.github" "$2/.github"
  cmp "$1/.groma/generated.json" "$2/.groma/generated.json"
  listing "$1" > "$W/l1"
  listing "$2" > "$W/l2"
  diff "$W/l1" "$W/l2"
}

@test "parity: materialize.sh and groma init --yes give identical copies and generated.json" {
  command -v node >/dev/null 2>&1 || skip "node not installed"
  for c in npx claude openspec; do
    printf '#!/bin/sh\nexit 0\n' > "$W/stubs/$c"
    chmod +x "$W/stubs/$c"
  done
  sh "$ROOT/tests/fixtures/generate.sh" "$W/cli" node-prisma >/dev/null
  sh "$ROOT/tests/fixtures/generate.sh" "$W/sh" node-prisma >/dev/null
  A="$W/cli/node-prisma"
  B="$W/sh/node-prisma"
  # a foreign folder on both sides: conflict, not copied
  for d in "$A" "$B"; do
    mkdir -p "$d/.github/skills/groma-loop"
    echo mine > "$d/.github/skills/groma-loop/SKILL.md"
  done

  run node "$GROMA" init "$A" --agents claude,copilot --methodology none --skills none --yes
  [ "$status" -eq 0 ]
  run sh "$M" --agents claude,copilot "$B"
  [ "$status" -eq 0 ]
  assert_output_contains "conflict	.github/skills/groma-loop"
  same_result "$A" "$B"
  [ "$(cat "$B/.github/skills/groma-loop/SKILL.md")" = mine ]

  # the same history on both sides, then update: an old unchanged copy, an
  # edited copy, a removed skill (one file unchanged, one edited)
  for d in "$A" "$B"; do
    P=$d
    printf 'old version' > "$d/.claude/skills/groma-detect/SKILL.md"
    record .claude/skills/groma-detect/SKILL.md 'old version'
    printf 'my edit' > "$d/.github/skills/groma-survey/SKILL.md"
    mkdir -p "$d/.claude/skills/groma-old/sub"
    printf 'old' > "$d/.claude/skills/groma-old/sub/a.md"
    printf 'edited' > "$d/.claude/skills/groma-old/notes.md"
    record .claude/skills/groma-old/sub/a.md 'old'
    record .claude/skills/groma-old/notes.md 'original'
  done
  run node "$GROMA" update "$A" --yes
  [ "$status" -eq 0 ]
  assert_output_contains "1 updated, 0 created, 1 removed"
  run sh "$M" --update --agents claude,copilot "$B"
  [ "$status" -eq 0 ]
  assert_output_contains "created=0	updated=1	removed=1	edited=2	conflicts=1"
  same_result "$A" "$B"
  [ ! -e "$B/.claude/skills/groma-old/sub" ]
  [ "$(cat "$B/.github/skills/groma-survey/SKILL.md")" = 'my edit' ]
}
