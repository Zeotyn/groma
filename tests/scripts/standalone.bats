#!/usr/bin/env bats
# Each skill installed alone (npx skills add --skill <name>) must work from its
# own folder: no reference into a sibling folder except a listed procedure
# hand-off (scripts/handoffs.txt), every Markdown link and $HERE path resolves,
# and the scripts that read shared files run.

load helpers

HANDOFFS="$ROOT/scripts/handoffs.txt"

setup() {
  P="$BATS_TEST_TMPDIR/project"
  mkdir -p "$P/.agents/skills"
}

# install_alone <skill>: copy the skill folder, and nothing else, into the project
install_alone() {
  cp -R "$ROOT/skills/$1" "$P/.agents/skills/$1"
  SK="$P/.agents/skills/$1"
  NAME=$1
}

# Every reference into a sibling folder must be a listed hand-off.
check_sibling_refs() {
  bad=""
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    file=${hit%%:*}
    ref=${hit##*:}
    if ! grep -qxF "skills/$NAME/${file#./} $ref" "$HANDOFFS"; then
      bad="$bad
skills/$NAME/${file#./}: $ref"
    fi
  done <<EOF
$(cd "$SK" && grep -rnoE '(\.\./)+groma[a-z-]*/[A-Za-z0-9_./-]*' . | sed -E 's/^([^:]*):[0-9]+:/\1:/')
EOF
  [ -z "$bad" ] || { echo "sibling references that are not listed hand-offs:$bad"; return 1; }
}

# Every relative Markdown link resolves inside the installed folder.
check_links() {
  bad=""
  while IFS= read -r md; do
    dir=$(dirname "$md")
    for target in $(sed '/^```/,/^```/d' "$md" | grep -oE '\]\([^) ]+\)' | sed -E 's/^\]\(//; s/\)$//'); do
      case "$target" in
        *:*|'#'*|*'{{'*|*'<'*) continue ;;
      esac
      path=${target%%#*}
      [ -n "$path" ] || continue
      [ -e "$dir/$path" ] || bad="$bad
${md#"$SK"/}: $target"
    done
  done <<EOF
$(find "$SK" -name '*.md')
EOF
  [ -z "$bad" ] || { echo "broken links:$bad"; return 1; }
}

# Every "$HERE/..." path in a script resolves next to that script.
check_here_paths() {
  bad=""
  for s in "$SK"/scripts/*.sh; do
    [ -f "$s" ] || continue
    for rel in $(grep -oE '"\$HERE/[^"]+"' "$s" | sed -E 's/^"\$HERE\///; s/"$//'); do
      [ -e "$(dirname "$s")/$rel" ] || bad="$bad
${s#"$SK"/}: \$HERE/$rel"
    done
  done
  [ -z "$bad" ] || { echo "missing script paths:$bad"; return 1; }
}

check_refs() {
  check_sibling_refs
  check_links
  check_here_paths
}

# a small git project with an .editorconfig, a change and a doc
project_fixture() {
  make_repo "$P"
  printf 'root = true\n[*]\nindent_style = space\n' > "$P/.editorconfig"
  mkdir -p "$P/src" "$P/docs" "$P/openspec/changes/c001-x"
  printf 'x = 1\n' > "$P/src/a.py"
  printf -- '---\nsources: [src/]\n---\n# Architecture\n' > "$P/docs/architecture.md"
  commit_at "$P" 2026-10-01 base
  printf '## Why\n\nx\n' > "$P/openspec/changes/c001-x/proposal.md"
  printf -- '- [x] 1.1 done\n' > "$P/openspec/changes/c001-x/tasks.md"
  commit_at "$P" 2026-11-01 propose
  printf 'x = 2\n' > "$P/src/a.py"
  commit_at "$P" 2026-11-02 code
}

valid_config() {
  mkdir -p "$P/.groma"
  cat > "$P/.groma/config.yaml" <<'EOF'
schema: 1
initialized_with: groma@0.1.0
project:
  name: shop
  has_ui: false
project_type: brownfield
methodology: openspec
workflow: none
agents: [claude]
skills:
  writing: [none]
docs:
  gate: review
conventions:
  changes:
    enabled: true
EOF
}

@test "the hand-off list names existing files" {
  while read -r file ref; do
    case "$file" in ''|'#'*) continue ;; esac
    [ -f "$ROOT/$file" ] || { echo "listed file missing: $file"; return 1; }
    grep -qF -- "$ref" "$ROOT/$file" || { echo "$file does not mention $ref"; return 1; }
  done < "$HANDOFFS"
}

@test "groma-detect alone" {
  install_alone groma-detect
  check_refs
  project_fixture
  run sh "$SK/scripts/detect.sh" "$P"
  [ "$status" -eq 0 ]
  run sh "$SK/scripts/git-practice.sh" "$P"
  [ "$status" -eq 0 ]
}

@test "groma-survey alone" {
  install_alone groma-survey
  check_refs
  project_fixture
  run sh "$SK/scripts/style-drift.sh" "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "summary	tools=1	drift=0"
  run sh "$SK/scripts/detect.sh" "$P"
  [ "$status" -eq 0 ]
}

@test "groma alone" {
  install_alone groma
  check_refs
  project_fixture
  run sh "$SK/scripts/style-drift.sh" "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "summary	tools=1	drift=0"
  run sh "$SK/scripts/git-practice.sh" "$P"
  [ "$status" -eq 0 ]
  valid_config
  run sh "$SK/scripts/validate-config.sh" "$P/.groma/config.yaml" --catalog "$SK/catalog.yaml"
  [ "$status" -eq 0 ]
}

@test "groma-skills alone" {
  install_alone groma-skills
  check_refs
  valid_config
  run sh "$SK/scripts/validate-config.sh" "$P/.groma/config.yaml" --catalog "$SK/catalog.yaml"
  [ "$status" -eq 0 ]
  [ -f "$SK/agents.yaml" ]
}

@test "groma-agents alone" {
  install_alone groma-agents
  check_refs
  [ -f "$SK/agents.yaml" ]
}

@test "groma-lay-out alone" {
  install_alone groma-lay-out
  check_refs
  project_fixture
  run sh "$SK/scripts/docs-impact.sh" --root "$P" "$P/openspec/changes/c001-x"
  [ "$status" -eq 0 ]
  assert_output_contains "impact	docs/architecture.md"
}

@test "groma-methodology alone: status uses its own docs-impact copy" {
  install_alone groma-methodology
  check_refs
  project_fixture
  run sh "$SK/scripts/status.sh" --root "$P" --today 2026-11-04
  [ "$status" -eq 0 ]
  assert_output_contains "c001-x  1/1 tasks → update docs/architecture.md or add a Docs: task line"
  run sh "$SK/scripts/check-prereqs.sh"
  [ "$status" -le 1 ]
}

@test "groma-loop alone" {
  install_alone groma-loop
  check_refs
  project_fixture
  run sh "$SK/scripts/docs-impact.sh" --root "$P" "$P/openspec/changes/c001-x"
  [ "$status" -eq 0 ]
  assert_output_contains "impact	docs/architecture.md"
}
