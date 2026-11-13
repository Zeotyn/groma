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
  stub_claude ''
}

# suite <dir> [skill...]: a copy of the groma skills (default: all) to run the script from
suite() {
  d=$1; shift
  mkdir -p "$d/skills"
  if [ $# -eq 0 ]; then cp -R "$ROOT"/skills/* "$d/skills/"; else for s in "$@"; do cp -R "$ROOT/skills/$s" "$d/skills/"; done; fi
  MS="$d/skills/groma/scripts/materialize.sh"
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

@test "files a shipped skill no longer has are deleted only when unchanged" {
  sh "$M" --agents claude "$P" >/dev/null
  mkdir -p "$P/.claude/skills/groma-detect/gone/sub"
  printf 'old' > "$P/.claude/skills/groma-detect/gone/sub/a.md"
  printf 'old' > "$P/.claude/skills/groma-detect/old.md"
  printf 'edited' > "$P/.claude/skills/groma-detect/notes.md"
  record .claude/skills/groma-detect/gone/sub/a.md 'old'
  record .claude/skills/groma-detect/old.md 'old'
  record .claude/skills/groma-detect/notes.md 'original'
  run sh "$M" --update --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "remove	.claude/skills/groma-detect/old.md"
  assert_output_contains "edited	.claude/skills/groma-detect/notes.md"
  assert_output_contains "removed=2	edited=1"
  [ ! -e "$P/.claude/skills/groma-detect/old.md" ]
  [ -f "$P/.claude/skills/groma-detect/notes.md" ]
  # folders the removal left empty go too
  [ ! -e "$P/.claude/skills/groma-detect/gone" ]
  [ -f "$P/.claude/skills/groma-detect/SKILL.md" ]
  grep -q 'groma-detect/notes.md' "$P/.groma/generated.json"
  run grep -c 'groma-detect/old.md\|groma-detect/gone' "$P/.groma/generated.json"
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
  run grep -c disable "$W/calls.log"
  [ "$output" = 0 ]
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
  # the path already proves the plugin: claude is not called
  [ ! -e "$W/calls.log" ]
  # any other folder named plugins proves nothing
  S="$W/work/plugins/mine/skills"
  mkdir -p "$S" "$W/p2"
  cp -R "$ROOT/skills/groma" "$S/"
  run sh "$S/groma/scripts/materialize.sh" --agents claude "$W/p2"
  [ "$status" -eq 0 ]
  assert_output_not_contains "plugin	"
}

@test "plugin check: claude gets no stdin and is stopped after the timeout" {
  printf '#!/bin/sh\ncat >/dev/null\nsleep 30\necho groma@groma\n' > "$W/stubs/claude"
  chmod +x "$W/stubs/claude"
  start=$(date +%s)
  GROMA_PLUGIN_CHECK_TIMEOUT=1 run sh "$M" --agents claude "$P"
  [ "$status" -eq 0 ]
  [ $(( $(date +%s) - start )) -lt 15 ]
  assert_output_not_contains "plugin	"
  assert_output_contains "summary	created="
}

# --- what a run may delete -----------------------------------------------------

@test "a smaller source never removes the copies of skills it does not ship" {
  sh "$M" --agents claude "$P" >/dev/null
  cp "$P/.groma/generated.json" "$W/before"
  find "$P/.claude" -type f | LC_ALL=C sort > "$W/files"
  # --skills selection
  run sh "$M" --update --skills groma --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "created=0	updated=0	removed=0	edited=0	conflicts=0"
  # a bundle: only some skill folders next to the script
  suite "$W/bundle" groma groma-detect groma-survey groma-lay-out
  run sh "$MS" --update --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "created=0	updated=0	removed=0	edited=0	conflicts=0"
  find "$P/.claude" -type f | LC_ALL=C sort > "$W/files2"
  cmp "$W/files" "$W/files2"
  cmp "$W/before" "$P/.groma/generated.json"
}

@test "an older source refuses to downgrade a newer project; --force never removes newer skills" {
  suite "$W/new"
  echo 9.1.0 > "$W/new/skills/groma/VERSION"
  cp -R "$W/new/skills/groma-detect" "$W/new/skills/groma-future"
  sh "$MS" --agents claude "$P" >/dev/null
  [ -f "$P/.claude/skills/groma-future/SKILL.md" ]
  cp "$P/.groma/generated.json" "$W/before"
  run sh "$M" --update --agents claude "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "9.1.0"
  assert_output_contains "newer"
  cmp "$W/before" "$P/.groma/generated.json"
  grep -q 'generatedBy: groma@9.1.0' "$P/.claude/skills/groma/SKILL.md"
  run sh "$M" --update --dry-run --agents claude "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "--allow-downgrade"
  # --force alone still refuses a downgrade
  run sh "$M" --update --force --agents claude "$P"
  [ "$status" -eq 1 ]
  cmp "$W/before" "$P/.groma/generated.json"
  grep -q 'generatedBy: groma@9.1.0' "$P/.claude/skills/groma/SKILL.md"
  run sh "$M" --update --allow-downgrade --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "removed=0"
  grep -q "generatedBy: groma@$VERSION" "$P/.claude/skills/groma/SKILL.md"
  [ -f "$P/.claude/skills/groma-future/SKILL.md" ]
  grep -q 'groma-future/SKILL.md' "$P/.groma/generated.json"
}

@test "a pre-release is older than its release" {
  suite "$W/rel"
  echo 9.1.0 > "$W/rel/skills/groma/VERSION"
  suite "$W/pre"
  echo 9.1.0-rc.1 > "$W/pre/skills/groma/VERSION"
  sh "$W/rel/skills/groma/scripts/materialize.sh" --agents claude "$P" >/dev/null
  run sh "$W/pre/skills/groma/scripts/materialize.sh" --update --agents claude "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "newer"
  # the other way round is an upgrade
  mkdir "$W/p2"
  sh "$W/pre/skills/groma/scripts/materialize.sh" --agents claude "$W/p2" >/dev/null
  run sh "$W/rel/skills/groma/scripts/materialize.sh" --update --agents claude "$W/p2"
  [ "$status" -eq 0 ]
}

@test "retired skills are removed only when listed in retired-skills.txt and inside the --skills selection" {
  sh "$M" --agents claude "$P" >/dev/null
  mkdir -p "$P/.claude/skills/groma-old" "$P/.claude/skills/groma-other"
  printf 'old' > "$P/.claude/skills/groma-old/SKILL.md"
  printf 'edited' > "$P/.claude/skills/groma-old/notes.md"
  printf 'old' > "$P/.claude/skills/groma-other/SKILL.md"
  record .claude/skills/groma-old/SKILL.md 'old'
  record .claude/skills/groma-old/notes.md 'original'
  record .claude/skills/groma-other/SKILL.md 'old'
  suite "$W/next"
  printf '# comment\ngroma-old\n' >> "$W/next/skills/groma/retired-skills.txt"
  run sh "$MS" --update --skills groma,groma-detect --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "removed=0"
  run sh "$MS" --update --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "remove	.claude/skills/groma-old/SKILL.md"
  assert_output_contains "edited	.claude/skills/groma-old/notes.md"
  assert_output_contains "removed=1	edited=1"
  [ ! -e "$P/.claude/skills/groma-old/SKILL.md" ]
  [ -f "$P/.claude/skills/groma-old/notes.md" ]
  # a skill that is neither shipped nor listed stays, with its record
  [ -f "$P/.claude/skills/groma-other/SKILL.md" ]
  grep -q 'groma-other/SKILL.md' "$P/.groma/generated.json"
}

@test "--update does nothing when the copy was declined (skills_copy skipped, no generated.json)" {
  mkdir -p "$P/.groma"
  printf 'schema: 1\nagents: [claude]\nsteps:\n  agents: done\n  skills_copy: skipped   # declined\n' > "$P/.groma/config.yaml"
  run sh "$M" --update "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "note	"
  assert_output_contains "created=0	updated=0	removed=0	edited=0	conflicts=0"
  [ ! -e "$P/.claude" ]
  [ ! -e "$P/.groma/generated.json" ]
  run sh "$M" --update --agents claude "$P"
  [ ! -e "$P/.claude" ]
  printf 'schema: 1\nagents: [claude]\nsteps:\n  skills_copy: "skipped"\n' > "$P/.groma/config.yaml"
  run sh "$M" --update "$P"
  [ ! -e "$P/.claude" ]
  printf 'schema: 1\nagents: [claude]\nsteps: { agents: done, skills_copy: skipped }\n' > "$P/.groma/config.yaml"
  run sh "$M" --update "$P"
  [ ! -e "$P/.claude" ]
  # asked for explicitly without --update: copies
  run sh "$M" --agents claude "$P"
  [ -f "$P/.claude/skills/groma/SKILL.md" ]
}

# --- where the script refuses to run or write -------------------------------------

@test "run from copies that groma made: refused, nothing changes" {
  sh "$M" --agents claude,codex "$P" >/dev/null
  printf 'my edit' > "$P/.claude/skills/groma-survey/SKILL.md"
  echo mine > "$P/.claude/skills/groma/notes-of-mine.md"
  cp "$P/.groma/generated.json" "$W/before"
  cp "$P/.claude/skills/groma/SKILL.md" "$W/skill-before"
  run sh "$P/.claude/skills/groma/scripts/materialize.sh" --update --agents claude,codex "$P"
  [ "$status" -eq 1 ]
  assert_output_contains "copy that groma made"
  assert_output_contains "npx groma-cli update"
  cmp "$W/before" "$P/.groma/generated.json"
  [ ! -e "$P/.agents/skills/groma/notes-of-mine.md" ]
  run grep -c 'my edit' "$P/.agents/skills/groma-survey/SKILL.md"
  [ "$output" = 0 ]
  # through a link to the project, and through another spelling of its path
  ln -s "$P" "$W/alias"
  run sh "$W/alias/.claude/skills/groma/scripts/materialize.sh" --update --agents claude "$P"
  [ "$status" -eq 1 ]
  run sh "$W/alias/.claude/skills/groma/scripts/materialize.sh" --update --agents claude "$W/alias"
  [ "$status" -eq 1 ]
  UP=$(printf '%s' "$P" | tr '[:lower:]' '[:upper:]')
  if [ -d "$UP/.claude" ]; then
    run sh "$UP/.claude/skills/groma/scripts/materialize.sh" --update --agents claude "$P"
    [ "$status" -eq 1 ]
  fi
  # the copies of another project are no source either
  mkdir "$W/other"
  run sh "$P/.claude/skills/groma/scripts/materialize.sh" --agents claude "$W/other"
  [ "$status" -eq 1 ]
  [ -z "$(ls -A "$W/other")" ]
  cmp "$W/skill-before" "$P/.claude/skills/groma/SKILL.md"
  [ "$(grep -c '^  generatedBy:' "$P/.claude/skills/groma/SKILL.md")" -eq 1 ]
}

@test "a project-level install as source: other agents get copies, the source folder is never overwritten" {
  # npx skills add (project level): real folders in .agents/skills, links in .claude/skills
  mkdir -p "$P/.agents/skills" "$P/.claude/skills"
  cp -R "$ROOT"/skills/* "$P/.agents/skills/"
  for s in "$ROOT"/skills/*/; do ln -s "../../.agents/skills/$(basename "$s")" "$P/.claude/skills/$(basename "$s")"; done
  (cd "$P" && find .agents -type f -exec cksum {} + | LC_ALL=C sort -k 3) > "$W/src-before"
  run sh "$P/.claude/skills/groma/scripts/materialize.sh" --agents claude,codex,copilot "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "note	.agents/skills"
  assert_output_contains "conflict	.claude/skills/groma"
  assert_output_not_contains "create	.agents"
  assert_output_not_contains "create	.claude"
  [ -f "$P/.github/skills/groma/SKILL.md" ]
  grep -q "generatedBy: groma@$VERSION" "$P/.github/skills/groma/SKILL.md"
  (cd "$P" && find .agents -type f -exec cksum {} + | LC_ALL=C sort -k 3) > "$W/src-after"
  cmp "$W/src-before" "$W/src-after"
  [ -L "$P/.claude/skills/groma" ]
  run grep -c '"\.agents\|"\.claude' "$P/.groma/generated.json"
  [ "$output" = 0 ]
  # the whole skills folder linked to the source folder
  rm -rf "$P/.claude/skills" && ln -s ../.agents/skills "$P/.claude/skills"
  run sh "$P/.agents/skills/groma/scripts/materialize.sh" --update --agents claude,copilot "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "note	.claude/skills"
  (cd "$P" && find .agents -type f -exec cksum {} + | LC_ALL=C sort -k 3) > "$W/src-after"
  cmp "$W/src-before" "$W/src-after"
}

@test "groma's own repository is refused with a clear message" {
  R="$W/repo"
  suite "$R"
  mkdir -p "$R/.claude-plugin"
  run sh "$R/skills/groma/scripts/materialize.sh" --agents claude "$R"
  [ "$status" -eq 1 ]
  assert_output_contains "source repository"
  [ ! -e "$R/.claude/skills" ]
  [ ! -e "$R/.groma" ]
}

@test "a symlinked skill folder or subfolder is a conflict and is never written into" {
  sh "$M" --agents claude "$P" >/dev/null
  mkdir -p "$W/fork" "$W/sub"
  mv "$P/.claude/skills/groma-survey" "$W/fork/groma-survey"
  ln -s "$W/fork/groma-survey" "$P/.claude/skills/groma-survey"
  mv "$P/.claude/skills/groma-detect/scripts" "$W/sub/scripts"
  ln -s "$W/sub/scripts" "$P/.claude/skills/groma-detect/scripts"
  printf 'theirs' > "$W/fork/groma-survey/SKILL.md"
  printf 'theirs' > "$W/sub/scripts/detect.sh"
  rm "$W/fork/groma-survey/scripts/freshness.sh"
  echo keep > "$W/fork/groma-survey/extra.md"
  (cd "$W" && find fork sub -type f -exec cksum {} + | LC_ALL=C sort -k 3) > "$W/outside-before"
  run sh "$M" --update --force --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "conflict	.claude/skills/groma-survey"
  assert_output_contains "conflict	.claude/skills/groma-detect/scripts"
  assert_output_contains "created=0	updated=0	removed=0	edited=0	conflicts=2"
  (cd "$W" && find fork sub -type f -exec cksum {} + | LC_ALL=C sort -k 3) > "$W/outside-after"
  cmp "$W/outside-before" "$W/outside-after"
  [ -L "$P/.claude/skills/groma-survey" ]
}

@test "a skills folder that leads out of the project is a conflict" {
  mkdir -p "$W/elsewhere" "$P/.claude"
  ln -s "$W/elsewhere" "$P/.claude/skills"
  ln -s "$W/elsewhere" "$P/.github"
  run sh "$M" --agents claude,copilot,codex "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "conflict	.claude/skills"
  assert_output_contains "conflict	.github/skills"
  [ -z "$(ls -A "$W/elsewhere")" ]
  [ -f "$P/.agents/skills/groma/SKILL.md" ]
  run grep -c '"\.claude\|"\.github' "$P/.groma/generated.json"
  [ "$output" = 0 ]
}

@test "a skills folder linked to another one inside the project gives no false edits" {
  mkdir -p "$P/.agents/skills" "$P/.claude"
  ln -s ../.agents/skills "$P/.claude/skills"
  run sh "$M" --agents claude,codex "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "edited=0	conflicts=0"
  [ -f "$P/.agents/skills/groma/SKILL.md" ]
  run sh "$M" --update --agents claude,codex "$P"
  [ "$status" -eq 0 ]
  [ "$output" = "summary	created=0	updated=0	removed=0	edited=0	conflicts=0	agents=claude,codex	version=$VERSION	dry_run=0" ]
}

@test "a project path with spaces works; a file the script cannot copy fails before anything is written" {
  Q="$W/pro ject é"
  mkdir -p "$Q"
  suite "$W/su ite" groma groma-detect
  run sh "$MS" --agents claude "$Q"
  [ "$status" -eq 0 ]
  [ -f "$Q/.claude/skills/groma-detect/scripts/detect.sh" ]
  run sh "$MS" --update --agents claude "$Q"
  assert_output_contains "created=0	updated=0	removed=0	edited=0	conflicts=0"

  printf 'x' > "$W/su ite/skills/groma-detect/tab	name.md"
  mkdir "$W/p3"
  run sh "$MS" --agents claude "$W/p3"
  [ "$status" -eq 1 ]
  assert_output_contains "tab"
  [ -z "$(ls -A "$W/p3")" ]
}

@test "a failed write leaves a generated.json that records the files already written" {
  sh "$M" --agents claude "$P" >/dev/null
  rm -rf "$P/.claude/skills/groma-agents" "$P/.claude/skills/groma-survey/SKILL.md"
  chmod 555 "$P/.claude/skills/groma-survey"
  run sh "$M" --update --agents claude "$P"
  chmod 755 "$P/.claude/skills/groma-survey"
  [ "$status" -ne 0 ]
  # groma-agents was re-created before the failure and is recorded, so the next run owns it
  [ -f "$P/.claude/skills/groma-agents/SKILL.md" ]
  grep -q '".claude/skills/groma-agents/SKILL.md"' "$P/.groma/generated.json"
  run sh "$M" --update --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "conflicts=0"
  [ -f "$P/.claude/skills/groma-survey/SKILL.md" ]
}

@test "killed while writing: the next run owns the files already written" {
  # cp that kills the script after 30 copies into the project
  printf '#!/bin/sh\n/bin/cp "$@"\ncase "$*" in *"%s/"*) n=$(cat "%s" 2>/dev/null || echo 0); n=$((n + 1)); echo $n > "%s"; [ $n -lt 30 ] || kill -9 $PPID ;; esac\nexit 0\n' "$P" "$W/n" "$W/n" > "$W/stubs/cp"
  chmod +x "$W/stubs/cp"
  run sh "$M" --agents claude "$P"
  [ "$status" -ne 0 ]
  rm "$W/stubs/cp"
  [ "$(find "$P/.claude" -type f | wc -l | tr -d ' ')" -ge 29 ]
  [ -f "$P/.groma/generated.json" ]
  run sh "$M" --agents claude "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "updated=0	removed=0	edited=0	conflicts=0"
  run sh "$M" --update --agents claude "$P"
  [ "$output" = "summary	created=0	updated=0	removed=0	edited=0	conflicts=0	agents=claude	version=$VERSION	dry_run=0" ]
  [ -z "$(find "$P/.claude" -name '.groma-tmp*')" ]
}

@test "generatedBy: the script writes the same bytes as the CLI for odd frontmatter" {
  command -v node >/dev/null 2>&1 || skip "node not installed"
  S="$W/odd/skills"
  mkdir -p "$S/groma/scripts"
  cp "$M" "$S/groma/scripts/"
  cp "$ROOT/skills/groma/agents.yaml" "$S/groma/"
  echo 1.2.3 > "$S/groma/VERSION"
  printf -- '---\nname: groma\n---\n' > "$S/groma/SKILL.md"
  c() { mkdir -p "$S/groma-$1"; printf -- "$2" > "$S/groma-$1/SKILL.md"; }
  c bom '\357\273\277---\nname: x\n---\nbody\n'
  c crlf '---\r\nname: x\r\n---\r\nbody\r\n'
  c crlfmeta '---\nname: x\nmetadata:\r\n  a: b\n---\n'
  c closenoeol '---\nname: x\n---'
  c empty ''
  c emptyfm '---\n---\nbody\n---\nmore\n'
  c fourdash '---\nname: x\n----\nbody\n'
  c hasgen '---\nname: x\nmetadata:\n  generatedBy: groma@0.1.0\n---\n'
  c inlinemeta '---\nname: x\nmetadata: {a: b}\n---\n'
  c metanoeol '---\nname: x\nmetadata:'
  c metaspace '---\nname: x\nmetadata: \t\n  a: b\n---\nbody'
  c nested '---\nname: x\nother:\n  metadata:\n    a: b\n---\n'
  c nofm '# title\n\n---\nname: x\n---\n'
  c unclosed '---\nname: x\nbody\n'
  c latemeta '---\nname: x\n---\nmetadata:\n---\n'
  c hasgenlater '---\nname: x\nmetadata:\n  a: b\n  generatedBy: groma@0.1.0\n  c: d\n---\nbody\n'
  c blank '\n---\nname: x\n---\n'
  c onlydash '---\n'
  run sh "$S/groma/scripts/materialize.sh" --agents claude "$P"
  [ "$status" -eq 0 ]
  cat > "$W/want.mjs" <<JS
import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { addGeneratedBy } from '$ROOT/cli/skills.js';
for (const s of readdirSync('$S')) {
  const b = readFileSync('$S/' + s + '/SKILL.md');
  writeFileSync('$W/want-' + s, Buffer.from(addGeneratedBy(b.toString('utf8'), 'groma@1.2.3')));
}
JS
  node "$W/want.mjs"
  for d in "$S"/*/; do
    n=$(basename "$d")
    cmp "$W/want-$n" "$P/.claude/skills/$n/SKILL.md"
  done
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
  # edited copy, files a shipped skill no longer has (one unchanged, one edited),
  # a recorded skill that is neither shipped nor retired
  for d in "$A" "$B"; do
    P=$d
    printf 'old version' > "$d/.claude/skills/groma-detect/SKILL.md"
    record .claude/skills/groma-detect/SKILL.md 'old version'
    printf 'my edit' > "$d/.github/skills/groma-survey/SKILL.md"
    mkdir -p "$d/.claude/skills/groma-detect/old/sub" "$d/.claude/skills/groma-gone"
    printf 'old' > "$d/.claude/skills/groma-detect/old/sub/a.md"
    printf 'edited' > "$d/.claude/skills/groma-detect/notes.md"
    printf 'old' > "$d/.claude/skills/groma-gone/SKILL.md"
    record .claude/skills/groma-detect/old/sub/a.md 'old'
    record .claude/skills/groma-detect/notes.md 'original'
    record .claude/skills/groma-gone/SKILL.md 'old'
  done
  run node "$GROMA" update "$A" --yes
  [ "$status" -eq 0 ]
  assert_output_contains "1 updated, 0 created, 1 removed"
  run sh "$M" --update --agents claude,copilot "$B"
  [ "$status" -eq 0 ]
  assert_output_contains "created=0	updated=1	removed=1	edited=2	conflicts=1"
  same_result "$A" "$B"
  [ ! -e "$B/.claude/skills/groma-detect/old" ]
  # a skill that is not shipped and not listed as retired stays on both paths
  [ -f "$B/.claude/skills/groma-gone/SKILL.md" ]
  grep -q 'groma-gone/SKILL.md' "$B/.groma/generated.json"
  [ "$(cat "$B/.github/skills/groma-survey/SKILL.md")" = 'my edit' ]
}

@test "parity: a skills folder linked to another one inside the project" {
  command -v node >/dev/null 2>&1 || skip "node not installed"
  for c in npx openspec; do
    printf '#!/bin/sh\nexit 0\n' > "$W/stubs/$c"
    chmod +x "$W/stubs/$c"
  done
  A="$W/cli-link"
  B="$W/sh-link"
  for d in "$A" "$B"; do
    mkdir -p "$d/.agents/skills" "$d/.claude"
    ln -s ../.agents/skills "$d/.claude/skills"
  done
  run node "$GROMA" init "$A" --agents claude,codex --methodology none --skills none --yes
  [ "$status" -eq 0 ]
  run sh "$M" --agents claude,codex "$B"
  [ "$status" -eq 0 ]
  diff -r "$A/.agents" "$B/.agents"
  cmp "$A/.groma/generated.json" "$B/.groma/generated.json"
  grep -q '".claude/skills/groma/SKILL.md"' "$B/.groma/generated.json"
  for d in "$A" "$B"; do
    P=$d
    printf 'old version' > "$d/.agents/skills/groma-detect/SKILL.md"
    record .agents/skills/groma-detect/SKILL.md 'old version'
    record .claude/skills/groma-detect/SKILL.md 'old version'
  done
  run node "$GROMA" update "$A" --yes
  [ "$status" -eq 0 ]
  run sh "$M" --update --agents claude,codex "$B"
  [ "$status" -eq 0 ]
  assert_output_contains "edited=0	conflicts=0"
  diff -r "$A/.agents" "$B/.agents"
  cmp "$A/.groma/generated.json" "$B/.groma/generated.json"
}
