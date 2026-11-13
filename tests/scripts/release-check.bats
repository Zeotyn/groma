#!/usr/bin/env bats

load helpers

S="$ROOT/scripts/release-check.sh"

# minimal release tree at version $1 in $R
tree() {
  R="$BATS_TEST_TMPDIR/r"
  mkdir -p "$R/.claude-plugin" "$R/.codex-plugin" "$R/.cursor-plugin" "$R/skills/groma"
  for m in .claude-plugin/plugin.json .codex-plugin/plugin.json .cursor-plugin/plugin.json gemini-extension.json; do
    printf '{ "name": "groma", "version": "%s" }\n' "$1" > "$R/$m"
  done
  cat > "$R/.claude-plugin/marketplace.json" <<EOF
{ "name": "groma", "owner": { "name": "o" },
  "plugins": [
    { "name": "groma", "source": "./", "version": "$1" },
    { "name": "groma-docs", "source": "./", "version": "$1", "skills": ["./skills/groma-detect"] },
    { "name": "groma-loop", "source": "./", "version": "$1", "skills": ["./skills/groma-loop"] } ] }
EOF
  printf '{ "name": "groma-cli", "version": "%s" }\n' "$1" > "$R/package.json"
  printf '%s\n' "$1" > "$R/skills/groma/VERSION"
  cat > "$R/CHANGELOG.md" <<EOF
# Changelog

## [Unreleased]

## [$1] - 2026-11-12

### Added

- First line of $1.
- Second line of $1.

## [0.0.1] - 2026-01-01

### Fixed

- Old entry.
EOF
}

@test "matching tag passes" {
  tree 0.3.0
  run sh "$S" --root "$R" v0.3.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"release v0.3.0: ok"* ]]
}

@test "tag that is not v<semver> fails" {
  tree 0.3.0
  run sh "$S" --root "$R" 0.3.0
  [ "$status" -eq 1 ]
  [[ "$output" == *"tag must look like v<major>.<minor>.<patch>"* ]]
  run sh "$S" --root "$R" v0.3
  [ "$status" -eq 1 ]
}

@test "a manifest with a different version fails and is named" {
  tree 0.3.0
  printf '{ "name": "groma-cli", "version": "0.2.2" }\n' > "$R/package.json"
  run sh "$S" --root "$R" v0.3.0
  [ "$status" -eq 1 ]
  [[ "$output" == *"package.json declares 0.2.2, tag is 0.3.0"* ]]
}

@test "the marketplace entry and VERSION are checked too" {
  tree 0.3.0
  printf '0.2.2\n' > "$R/skills/groma/VERSION"
  printf '{ "plugins": [ { "name": "groma", "version": "0.2.9" } ] }\n' > "$R/.claude-plugin/marketplace.json"
  run sh "$S" --root "$R" v0.3.0
  [ "$status" -eq 1 ]
  [[ "$output" == *"skills/groma/VERSION declares 0.2.2"* ]]
  [[ "$output" == *".claude-plugin/marketplace.json declares 0.2.9"* ]]
}

@test "every marketplace bundle is checked, not only the first" {
  tree 0.3.0
  sed -i.bak 's/"name": "groma-loop", "source": ".\/", "version": "0.3.0"/"name": "groma-loop", "source": ".\/", "version": "0.2.9"/' \
    "$R/.claude-plugin/marketplace.json"
  grep -q '"version": "0.2.9"' "$R/.claude-plugin/marketplace.json"
  run sh "$S" --root "$R" v0.3.0
  [ "$status" -eq 1 ]
  [[ "$output" == *".claude-plugin/marketplace.json declares 0.2.9 for groma-loop, tag is 0.3.0"* ]]
  [[ "$output" != *"for groma-docs"* ]]
}

@test "a marketplace bundle without a version fails" {
  tree 0.3.0
  sed -i.bak 's/"name": "groma-docs", "source": ".\/", "version": "0.3.0",/"name": "groma-docs", "source": ".\/",/' \
    "$R/.claude-plugin/marketplace.json"
  run sh "$S" --root "$R" v0.3.0
  [ "$status" -eq 1 ]
  [[ "$output" == *".claude-plugin/marketplace.json: 1 plugin entry declares no version"* ]]
}

@test "a missing manifest version fails" {
  tree 0.3.0
  printf '{ "name": "groma" }\n' > "$R/gemini-extension.json"
  run sh "$S" --root "$R" v0.3.0
  [ "$status" -eq 1 ]
  [[ "$output" == *"gemini-extension.json declares no version"* ]]
}

@test "release still under [Unreleased] fails" {
  tree 0.3.0
  sed -i.bak 's/^## \[0.3.0\] - 2026-11-12$//' "$R/CHANGELOG.md"
  run sh "$S" --root "$R" v0.3.0
  [ "$status" -eq 1 ]
  [[ "$output" == *"CHANGELOG.md has no section ## [0.3.0]"* ]]
}

@test "--notes prints exactly the version's section" {
  tree 0.3.0
  run sh "$S" --root "$R" --notes v0.3.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"### Added"* ]]
  [[ "$output" == *"- Second line of 0.3.0."* ]]
  [[ "$output" != *"## [0.3.0]"* ]]
  [[ "$output" != *"Old entry"* ]]
  [[ "$output" != *"Unreleased"* ]]
}

@test "this repository's current version passes its own check" {
  v=$(cat "$ROOT/skills/groma/VERSION")
  run sh "$S" "v$v"
  [ "$status" -eq 0 ]
}
