#!/usr/bin/env bats

load helpers

DI="$ROOT/skills/groma-lay-out/scripts/docs-impact.sh"

# fixture living-docs: docs on 2026-10-01, change c007-cache proposed on 2026-10-10,
# src/cache.js changed on 2026-10-15. design.md: D1 without, D2 "Use Redis" with Alternatives.
setup() {
  sh "$ROOT/tests/fixtures/generate.sh" "$BATS_TEST_TMPDIR/f" living-docs >/dev/null
  P="$BATS_TEST_TMPDIR/f/living-docs"
  CH="$P/openspec/changes/c007-cache"
}

di() { run sh "$DI" --root "$P" "$@"; }

@test "code changed since the proposal, doc not: impact line" {
  di openspec/changes/c007-cache
  [ "$status" -eq 0 ]
  assert_output_contains "impact	docs/architecture.md	src/cache.js"
  assert_output_contains "summary	impact=1	adr=1"
}

@test "docs whose sources did not change, ADRs and docs without sources are not reported" {
  di openspec/changes/c007-cache
  assert_output_not_contains "docs/data-model.md"
  assert_output_not_contains "docs/glossary.md"
  assert_output_not_contains "docs/adr/0001"
}

@test "doc updated in the change: no impact line" {
  echo "Now a Map." >> "$P/docs/architecture.md"
  di openspec/changes/c007-cache
  assert_output_not_contains "impact	docs/architecture.md"
  assert_output_contains "summary	impact=0"
}

@test "the change's own files do not count as changed sources" {
  printf -- '---\nsources: [openspec/]\n---\n# Roadmap\n' > "$P/docs/roadmap.md"
  commit_at "$P" 2026-10-02 roadmap
  di openspec/changes/c007-cache
  assert_output_not_contains "docs/roadmap.md"
}

@test "justified Docs: line clears the doc" {
  echo '- [x] Docs: `docs/architecture.md` unchanged, because the cache is internal' >> "$CH/tasks.md"
  di openspec/changes/c007-cache
  assert_output_not_contains "impact	docs/architecture.md"
}

@test "Docs: line without a reason does not clear the doc" {
  echo '- [x] Docs: docs/architecture.md unchanged' >> "$CH/tasks.md"
  di openspec/changes/c007-cache
  assert_output_contains "impact	docs/architecture.md	src/cache.js"
}

@test "decision with Alternatives needs an ADR, decision without does not" {
  di openspec/changes/c007-cache
  assert_output_contains "adr	c007-cache#D2	Use Redis"
  assert_output_not_contains "c007-cache#D1"
}

@test "ADR with matching origin covers the decision" {
  printf -- '---\nstatus: proposed\norigin: c007-cache#D2\n---\n# Use Redis\n' > "$P/docs/adr/0002-use-redis.md"
  di openspec/changes/c007-cache
  assert_output_not_contains "adr	c007-cache#D2"
  assert_output_contains "adr=0"
}

@test "adr_from marked: only decisions with ADR: yes" {
  mkdir -p "$P/.groma"
  printf 'docs:\n  gate: review\n  adr_from: marked\n' > "$P/.groma/config.yaml"
  sed -i.bak 's/^Every read goes through.*/&\
ADR: yes/' "$CH/design.md" && rm "$CH/design.md.bak"
  di openspec/changes/c007-cache
  assert_output_contains "adr	c007-cache#D1	Cache in front of reads"
  assert_output_not_contains "c007-cache#D2"
}

@test "adr_from off: no adr lines" {
  mkdir -p "$P/.groma"
  printf 'docs:\n  adr_from: off\n' > "$P/.groma/config.yaml"
  di openspec/changes/c007-cache
  assert_output_not_contains "adr	"
  assert_output_contains "adr=0"
}

@test "base defaults to the parent of the proposal commit" {
  di --base HEAD openspec/changes/c007-cache
  assert_output_contains "summary	impact=0"
  di openspec/changes/c007-cache
  assert_output_contains "summary	impact=1"
}

@test "uncommitted proposal: working tree against HEAD, announced" {
  mkdir -p "$P/openspec/changes/c008-items"
  echo "## Why" > "$P/openspec/changes/c008-items/proposal.md"
  echo "CREATE TABLE tag (id INTEGER);" >> "$P/src/db/schema.sql"
  di openspec/changes/c008-items
  [ "$status" -eq 0 ]
  assert_output_contains "note	proposal not committed, comparing the working tree with HEAD"
  assert_output_contains "impact	docs/data-model.md	src/db/schema.sql"
  assert_output_not_contains "src/cache.js"
}

@test "untracked files count as changed" {
  echo "x" > "$P/src/new.js"
  di openspec/changes/c007-cache
  assert_output_contains "impact	docs/architecture.md	src/cache.js src/new.js"
}

@test "--gate exits 4 on a non-empty report" {
  di --gate openspec/changes/c007-cache
  [ "$status" -eq 4 ]
}

@test "--gate on a clean change exits 0" {
  echo '- [x] Docs: docs/architecture.md unchanged, because internal' >> "$CH/tasks.md"
  printf -- '---\nstatus: proposed\norigin: c007-cache#D2\n---\n# Use Redis\n' > "$P/docs/adr/0002-use-redis.md"
  di --gate openspec/changes/c007-cache
  [ "$status" -eq 0 ]
  assert_output_contains "summary	impact=0	adr=0"
}

@test "absolute change path works from another directory" {
  cd "$BATS_TEST_TMPDIR"
  di "$CH"
  assert_output_contains "impact	docs/architecture.md	src/cache.js"
}

@test "missing change folder exits 2" {
  di openspec/changes/nope
  [ "$status" -eq 2 ]
}

@test "is read-only" {
  sh "$DI" --root "$P" openspec/changes/c007-cache >/dev/null
  [ -z "$(git -C "$P" status --porcelain)" ]
}

# --- review round 1 -----------------------------------------------------------------

@test "unknown --base exits 2" {
  di --base nosuchref --gate openspec/changes/c007-cache
  [ "$status" -eq 2 ]
}

@test "project in a subfolder of the repository" {
  M="$BATS_TEST_TMPDIR/mono"
  make_repo "$M"
  cp -R "$P/." "$M/app" && rm -rf "$M/app/.git"
  commit_at "$M" 2026-10-20 import
  echo "// more" >> "$M/app/src/cache.js"
  printf -- '- [x] 1.1 x\n' > "$M/app/openspec/changes/c007-cache/tasks.md"
  run sh "$DI" --root "$M/app" --base HEAD openspec/changes/c007-cache
  assert_output_contains "impact	docs/architecture.md	src/cache.js"
}

@test "paths with spaces and glob characters" {
  mkdir -p "$P/src/my dir"
  echo x > "$P/src/my dir/a b.js"
  echo x > "$P/src/*"
  di openspec/changes/c007-cache
  assert_output_contains "src/my dir/a b.js"
  assert_output_not_contains "docs/data-model.md"
}

@test "a rename reports the old location too" {
  git -C "$P" mv src/db/schema.sql src/schema.sql
  di openspec/changes/c007-cache
  assert_output_contains "impact	docs/data-model.md	src/db/schema.sql"
}

@test "Docs: lines count only as task lines" {
  echo 'Docs: docs/architecture.md unchanged, because prose' >> "$CH/tasks.md"
  di openspec/changes/c007-cache
  assert_output_contains "impact	docs/architecture.md"
  echo '- [ ] Docs: ./docs/architecture.md unchanged, because internal' >> "$CH/tasks.md"
  di openspec/changes/c007-cache
  assert_output_not_contains "impact	docs/architecture.md"
}

# --- base on a change branch (C006) ---------------------------------------------------

@test "on the change branch the base is the merge base with main" {
  git -C "$P" switch -q -c c007-cache
  git -C "$P" switch -q main
  echo "-- on main" >> "$P/src/db/schema.sql"
  commit_at "$P" 2026-10-20 "main schema"
  git -C "$P" switch -q c007-cache
  echo "// on the branch" >> "$P/src/cache.js"
  commit_at "$P" 2026-10-21 "branch cache"
  di openspec/changes/c007-cache
  [ "$status" -eq 0 ]
  assert_output_contains "note	on branch c007-cache, comparing with its merge base with main"
  assert_output_contains "impact	docs/architecture.md	src/cache.js"
  assert_output_not_contains "docs/data-model.md"
}

@test "a branch with another name falls back to the proposal commit" {
  git -C "$P" switch -q -c wip
  di openspec/changes/c007-cache
  assert_output_not_contains "note	on branch"
  assert_output_contains "impact	docs/architecture.md	src/cache.js"
}

@test "--base wins over the merge base" {
  git -C "$P" switch -q -c c007-cache
  di --base HEAD openspec/changes/c007-cache
  assert_output_not_contains "note	on branch"
  assert_output_contains "summary	impact=0"
}
