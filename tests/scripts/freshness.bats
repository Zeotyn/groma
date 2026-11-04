#!/usr/bin/env bats

load helpers

FRESH="$ROOT/skills/groma-survey/scripts/freshness.sh"

@test "django fixture: architecture.md is stale (no sources, code newer)" {
  sh "$ROOT/tests/fixtures/generate.sh" "$BATS_TEST_TMPDIR/f" python-django-stale-docs >/dev/null
  run sh "$FRESH" "$BATS_TEST_TMPDIR/f/python-django-stale-docs" --today 2026-11-04
  [ "$status" -eq 0 ]
  assert_output_contains "stale	docs/architecture.md	repository code changed on 2026-10-20, doc last changed 2024-02-01"
  assert_output_contains "summary	stale=1	fresh=0	unknown=0"
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
  assert_output_contains "summary	stale=0	fresh=0	unknown=0"
}

@test "no docs folder yields empty summary" {
  run sh "$FRESH" "$BATS_TEST_TMPDIR"
  [ "$status" -eq 0 ]
  assert_output_contains "summary	stale=0	fresh=0	unknown=0"
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
