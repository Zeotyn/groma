#!/usr/bin/env bats

load helpers

FRESH="$ROOT/skills/groma-survey/scripts/freshness.sh"

@test "django fixture: architecture.md is stale (no sources, code newer)" {
  sh "$ROOT/tests/fixtures/generate.sh" "$BATS_TEST_TMPDIR/f" python-django-stale-docs >/dev/null
  run sh "$FRESH" "$BATS_TEST_TMPDIR/f/python-django-stale-docs" --today 2026-11-04
  [ "$status" -eq 0 ]
  assert_output_contains "stale	docs/architecture.md	repository code changed on 2026-10-20, doc last changed 2024-02-01"
  assert_output_contains "summary	stale=1	fresh=0	unknown=0	broken=0"
}

@test "doc with sources is stale only when its sources changed later" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs" "$D/src/core" "$D/src/other"
  printf -- '---\ntitle: A\nsources: [src/core/]\n---\n# A\n' > "$D/docs/a.md"
  echo 1 > "$D/src/core/x.py"; echo 1 > "$D/src/other/y.py"
  commit_at "$D" 2025-01-01 init
  echo 2 > "$D/src/other/y.py"
  commit_at "$D" 2025-06-01 other
  run sh "$FRESH" "$D" --today 2025-06-02
  assert_output_contains "fresh	docs/a.md"
  echo 2 > "$D/src/core/x.py"
  commit_at "$D" 2025-07-01 core
  run sh "$FRESH" "$D" --today 2025-07-02
  assert_output_contains "stale	docs/a.md	code changed: src/core/ on 2025-07-01, doc last changed 2025-01-01"
}

@test "block-list sources are supported" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs" "$D/db"
  printf -- '---\nsources:\n  - db/\n  - "package.json"\n---\n' > "$D/docs/data-model.md"
  echo x > "$D/db/m1.sql"
  commit_at "$D" 2025-01-01 init
  echo y > "$D/package.json"
  commit_at "$D" 2025-02-01 pkg
  run sh "$FRESH" "$D" --today 2025-02-02
  assert_output_contains "stale	docs/data-model.md	code changed: package.json on 2025-02-01"
}

@test "review overdue is reported" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs"
  printf -- '---\nlast_reviewed: 2025-01-01\nreview_after_days: 90\nsources: [docs/]\n---\n' > "$D/docs/vision.md"
  commit_at "$D" 2025-01-01 init
  run sh "$FRESH" "$D" --today 2025-06-01
  assert_output_contains "stale	docs/vision.md	review overdue: last_reviewed 2025-01-01 is 151 days old (limit 90)"
}

@test "within review window and no code change is fresh" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs"
  printf -- '---\nlast_reviewed: 2025-01-01\nreview_after_days: 90\nsources: [docs/]\n---\n' > "$D/docs/vision.md"
  commit_at "$D" 2025-01-01 init
  run sh "$FRESH" "$D" --today 2025-02-01
  assert_output_contains "fresh	docs/vision.md"
}

@test "uncommitted doc is unknown" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  echo x > "$D/a.txt"; commit_at "$D" 2025-01-01 init
  mkdir -p "$D/docs"; echo "# new" > "$D/docs/new.md"
  run sh "$FRESH" "$D" --today 2025-01-02
  assert_output_contains "unknown	docs/new.md	not committed yet"
}

@test "groma's own report folder is ignored" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs/_groma"; echo "# r" > "$D/docs/_groma/findings.md"
  commit_at "$D" 2025-01-01 init
  run sh "$FRESH" "$D"
  assert_output_contains "summary	stale=0	fresh=0	unknown=0	broken=0"
}

@test "no docs folder yields empty summary" {
  run sh "$FRESH" "$BATS_TEST_TMPDIR"
  [ "$status" -eq 0 ]
  assert_output_contains "summary	stale=0	fresh=0	unknown=0	broken=0"
}

@test "does not modify the project" {
  sh "$ROOT/tests/fixtures/generate.sh" "$BATS_TEST_TMPDIR/f" python-django-stale-docs >/dev/null
  P="$BATS_TEST_TMPDIR/f/python-django-stale-docs"
  sh "$ROOT/tests/invariant/checksum.sh" snapshot "$P" "$BATS_TEST_TMPDIR/m" >/dev/null
  sh "$FRESH" "$P" >/dev/null
  run sh "$ROOT/tests/invariant/checksum.sh" verify "$P" "$BATS_TEST_TMPDIR/m"
  [ "$status" -eq 0 ]
  [ -z "$(git -C "$P" status --porcelain)" ]
}

@test "accepted ADR stays fresh after code changes" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs/adr" "$D/src"
  printf -- '---\nstatus: accepted\ndate: 2025-01-01\n---\n' > "$D/docs/adr/0003-use-postgres.md"
  echo 1 > "$D/src/a.py"
  commit_at "$D" 2025-01-01 init
  echo 2 > "$D/src/a.py"
  commit_at "$D" 2025-06-01 code
  run sh "$FRESH" "$D" --today 2025-06-02
  assert_output_contains "fresh	docs/adr/0003-use-postgres.md"
}

@test "proposed ADR older than 30 days is stale with its date" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs/adr"
  printf -- '---\nstatus: proposed\ndate: 2026-09-01\n---\n' > "$D/docs/adr/0009-cache-layer.md"
  commit_at "$D" 2026-10-20 init
  run sh "$FRESH" "$D" --today 2026-11-04
  assert_output_contains "stale	docs/adr/0009-cache-layer.md	proposed since 2026-09-01, accept or reject"
}

@test "proposed ADR without date falls back to its last commit" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs/adr"
  printf -- '---\nstatus: proposed\n---\n' > "$D/docs/adr/0009-cache-layer.md"
  commit_at "$D" 2026-09-01 init
  run sh "$FRESH" "$D" --today 2026-11-04
  assert_output_contains "stale	docs/adr/0009-cache-layer.md	proposed since 2026-09-01, accept or reject"
}

@test "proposed ADR younger than 30 days is fresh" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs/adr"
  printf -- '---\nstatus: proposed\ndate: 2026-10-20\n---\n' > "$D/docs/adr/0009-cache-layer.md"
  commit_at "$D" 2026-10-20 init
  run sh "$FRESH" "$D" --today 2026-11-04
  assert_output_contains "fresh	docs/adr/0009-cache-layer.md"
}

@test "--adr-days 0 flags every proposed ADR" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs/adr"
  printf -- '---\nstatus: proposed\ndate: 2026-11-03\n---\n' > "$D/docs/adr/0009-a.md"
  printf -- '---\nstatus: proposed\ndate: 2026-10-20\n---\n' > "$D/docs/adr/0010-b.md"
  printf -- '---\nstatus: accepted\ndate: 2026-10-20\n---\n' > "$D/docs/adr/0011-c.md"
  commit_at "$D" 2026-11-03 init
  run sh "$FRESH" "$D" --today 2026-11-04 --adr-days 0
  assert_output_contains "stale	docs/adr/0009-a.md	proposed since 2026-11-03"
  assert_output_contains "stale	docs/adr/0010-b.md	proposed since 2026-10-20"
  assert_output_contains "fresh	docs/adr/0011-c.md"
}

@test "index with docs sources is not stale when another doc changes" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs" "$D/src"
  printf -- '---\nsources: [docs/]\n---\n' > "$D/docs/README.md"
  echo v1 > "$D/docs/vision.md"; echo 1 > "$D/src/a.py"
  commit_at "$D" 2025-01-01 init
  echo v2 > "$D/docs/vision.md"; echo 2 > "$D/src/a.py"
  commit_at "$D" 2025-02-01 later
  run sh "$FRESH" "$D" --today 2025-02-02
  assert_output_contains "fresh	docs/README.md"
}

@test "missing source is broken and counted" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs" "$D/skills" "$D/openspec/changes/c001-x"
  printf -- '---\nsources: [skills/, openspec/changes/c001-x/design.md]\n---\n' > "$D/docs/concept.md"
  echo 1 > "$D/skills/a.sh"; echo d > "$D/openspec/changes/c001-x/design.md"
  commit_at "$D" 2025-01-01 init
  mkdir -p "$D/openspec/changes/archive"
  git -C "$D" mv openspec/changes/c001-x openspec/changes/archive/c001-x
  commit_at "$D" 2025-02-01 archive
  run sh "$FRESH" "$D" --today 2025-02-02
  assert_output_contains "broken	docs/concept.md	source missing: openspec/changes/c001-x/design.md"
  assert_output_not_contains "stale	docs/concept.md"
  assert_output_contains "summary	stale=0	fresh=0	unknown=0	broken=1"
}

@test "existing source under openspec/changes/ is broken" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs" "$D/openspec/changes/c002-y"
  printf -- '---\nsources: [openspec/changes/c002-y/design.md]\n---\n' > "$D/docs/a.md"
  echo d > "$D/openspec/changes/c002-y/design.md"
  commit_at "$D" 2025-01-01 init
  run sh "$FRESH" "$D" --today 2025-01-02
  assert_output_contains "broken	docs/a.md	source in change folder: openspec/changes/c002-y/design.md"
}

@test "broken doc that is also stale lists the stale reason after the broken paths" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs" "$D/src"
  printf -- '---\nsources: [src/, gone.txt]\n---\n' > "$D/docs/a.md"
  echo 1 > "$D/src/a.py"
  commit_at "$D" 2025-01-01 init
  echo 2 > "$D/src/a.py"
  commit_at "$D" 2025-02-01 code
  run sh "$FRESH" "$D" --today 2025-02-02
  assert_output_contains "broken	docs/a.md	source missing: gone.txt; code changed: src/ on 2025-02-01, doc last changed 2025-01-01"
}

@test "the change folder itself is a valid source" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs" "$D/openspec/changes/c002-y"
  printf -- '---\nsources: [openspec/changes/]\n---\n' > "$D/docs/roadmap.md"
  echo d > "$D/openspec/changes/c002-y/design.md"
  commit_at "$D" 2025-01-01 init
  run sh "$FRESH" "$D" --today 2025-01-02
  assert_output_contains "fresh	docs/roadmap.md"
}

@test "--docs with trailing slash or ./ prefix keeps ADR and docs-source rules" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs/adr"
  printf -- '---\nstatus: accepted\n---\n' > "$D/docs/adr/0001-a.md"
  printf -- '---\nsources: [docs/]\n---\n' > "$D/docs/README.md"
  echo 1 > "$D/docs/vision.md"; echo 1 > "$D/app.py"
  commit_at "$D" 2025-01-01 init
  echo 2 > "$D/docs/vision.md"; echo 2 > "$D/app.py"
  commit_at "$D" 2025-02-01 later
  for opt in docs/ ./docs; do
    run sh "$FRESH" "$D" --docs "$opt" --today 2025-02-02
    assert_output_contains "fresh	docs/adr/0001-a.md"
    assert_output_contains "fresh	docs/README.md"
  done
}

@test "ADR date in single quotes and invalid date fall back correctly" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs/adr"
  printf -- "---\nstatus: proposed\ndate: '2026-10-30'\n---\n" > "$D/docs/adr/0009-a.md"
  printf -- '---\nstatus: proposed\ndate: TBD\n---\n' > "$D/docs/adr/0010-b.md"
  commit_at "$D" 2026-10-30 init
  run sh "$FRESH" "$D" --today 2026-11-04
  assert_output_contains "fresh	docs/adr/0009-a.md"
  assert_output_contains "fresh	docs/adr/0010-b.md"
  run sh "$FRESH" "$D" --today 2026-12-31
  assert_output_contains "stale	docs/adr/0009-a.md	proposed since 2026-10-30"
  assert_output_contains "stale	docs/adr/0010-b.md	proposed since 2026-10-30"
}

@test "non-numeric --adr-days is rejected" {
  run sh "$FRESH" "$BATS_TEST_TMPDIR" --adr-days abc
  [ "$status" -eq 2 ]
}

@test "archived change paths are valid sources; ./ change paths are broken" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs" "$D/openspec/changes/archive/c001-x" "$D/openspec/changes/c002-y"
  echo d > "$D/openspec/changes/archive/c001-x/design.md"; echo d > "$D/openspec/changes/c002-y/design.md"
  printf -- '---\nsources: [openspec/changes/archive/c001-x/design.md]\n---\n' > "$D/docs/a.md"
  printf -- '---\nsources: [./openspec/changes/c002-y/design.md]\n---\n' > "$D/docs/b.md"
  commit_at "$D" 2025-01-01 init
  run sh "$FRESH" "$D" --today 2025-01-02
  assert_output_contains "fresh	docs/a.md"
  assert_output_contains "broken	docs/b.md	source in change folder: openspec/changes/c002-y/design.md"
}

@test "--docs ./ still scans the project root" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  echo "# a" > "$D/a.md"
  commit_at "$D" 2025-01-01 init
  run sh "$FRESH" "$D" --docs ./ --today 2025-01-02
  assert_output_contains "fresh	./a.md"
}

@test "bare archive folder is a valid source" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs" "$D/openspec/changes/archive/c001-x"
  echo d > "$D/openspec/changes/archive/c001-x/design.md"
  printf -- '---\nsources: [openspec/changes/archive]\n---\n' > "$D/docs/a.md"
  commit_at "$D" 2025-01-01 init
  run sh "$FRESH" "$D" --today 2025-01-02
  assert_output_contains "fresh	docs/a.md"
}

# Commit everything in <dir> at a full ISO timestamp.
commit_ts() {
  git -C "$1" add -A
  GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2" git -C "$1" commit -q -m "$3"
}

@test "doc reviewed on the day of a later source commit is fresh" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs" "$D/skills"
  printf -- '---\nlast_reviewed: 2026-11-04\nreview_after_days: 90\nsources: [skills/]\n---\n' > "$D/docs/architecture.md"
  echo 1 > "$D/skills/a.sh"
  commit_ts "$D" 2026-11-04T10:00:00Z docs
  echo 2 > "$D/skills/a.sh"
  commit_ts "$D" 2026-11-04T15:00:00Z fix
  run sh "$FRESH" "$D" --today 2026-11-04
  assert_output_contains "fresh	docs/architecture.md"
}

@test "source commit the day after last_reviewed is stale and names last_reviewed" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs" "$D/skills"
  printf -- '---\nlast_reviewed: 2026-11-04\nreview_after_days: 90\nsources: [skills/]\n---\n' > "$D/docs/architecture.md"
  echo 1 > "$D/skills/a.sh"
  commit_ts "$D" 2026-11-04T10:00:00Z docs
  echo 2 > "$D/skills/a.sh"
  commit_ts "$D" 2026-11-05T09:00:00Z fix
  run sh "$FRESH" "$D" --today 2026-11-05
  assert_output_contains "stale	docs/architecture.md	code changed: skills/ on 2026-11-05, doc last changed 2026-11-04, last_reviewed 2026-11-04"
}

@test "doc without last_reviewed is stale after a same-day source commit" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs" "$D/skills"
  printf -- '---\nsources: [skills/]\n---\n' > "$D/docs/architecture.md"
  echo 1 > "$D/skills/a.sh"
  commit_ts "$D" 2026-11-04T10:00:00Z docs
  echo 2 > "$D/skills/a.sh"
  commit_ts "$D" 2026-11-04T15:00:00Z fix
  run sh "$FRESH" "$D" --today 2026-11-04
  assert_output_contains "stale	docs/architecture.md	code changed: skills/ on 2026-11-04, doc last changed 2026-11-04"
  assert_output_not_contains "last_reviewed"
}

@test "doc without sources honors last_reviewed for repository code" {
  D="$BATS_TEST_TMPDIR/p"
  make_repo "$D"
  mkdir -p "$D/docs"
  printf -- '---\nlast_reviewed: 2026-11-04\n---\n' > "$D/docs/a.md"
  echo 1 > "$D/app.py"
  commit_ts "$D" 2026-11-04T10:00:00Z docs
  echo 2 > "$D/app.py"
  commit_ts "$D" 2026-11-04T15:00:00Z fix
  run sh "$FRESH" "$D" --today 2026-11-04
  assert_output_contains "fresh	docs/a.md"
  echo 3 > "$D/app.py"
  commit_ts "$D" 2026-11-05T09:00:00Z later
  run sh "$FRESH" "$D" --today 2026-11-05
  assert_output_contains "stale	docs/a.md	repository code changed on 2026-11-05, doc last changed 2026-11-04 (no sources in frontmatter), last_reviewed 2026-11-04"
}
