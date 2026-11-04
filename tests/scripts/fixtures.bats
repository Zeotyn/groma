#!/usr/bin/env bats

load helpers

GEN="$ROOT/tests/fixtures/generate.sh"

@test "generates all required fixtures" {
  run sh "$GEN" "$BATS_TEST_TMPDIR/f"
  [ "$status" -eq 0 ]
  for name in empty node-prisma java-flyway python-django-stale-docs go-no-db loop-openspec; do
    [ -d "$BATS_TEST_TMPDIR/f/$name/.git" ]
  done
}

@test "empty fixture has no commits and no files" {
  sh "$GEN" "$BATS_TEST_TMPDIR/f" empty
  run git -C "$BATS_TEST_TMPDIR/f/empty" rev-parse HEAD
  [ "$status" -ne 0 ]
  [ -z "$(ls -A "$BATS_TEST_TMPDIR/f/empty" | grep -v '^.git$')" ]
}

@test "history is deterministic across runs" {
  sh "$GEN" "$BATS_TEST_TMPDIR/a" java-flyway
  sh "$GEN" "$BATS_TEST_TMPDIR/b" java-flyway
  a=$(git -C "$BATS_TEST_TMPDIR/a/java-flyway" rev-parse HEAD)
  b=$(git -C "$BATS_TEST_TMPDIR/b/java-flyway" rev-parse HEAD)
  [ "$a" = "$b" ]
}

@test "django fixture docs are older than its code" {
  sh "$GEN" "$BATS_TEST_TMPDIR/f" python-django-stale-docs
  R="$BATS_TEST_TMPDIR/f/python-django-stale-docs"
  doc=$(git -C "$R" log -1 --format=%cs -- docs/architecture.md)
  code=$(git -C "$R" log -1 --format=%cs -- shop/)
  [ "$doc" = "2024-02-01" ]
  [ "$code" = "2026-10-20" ]
}

@test "unknown fixture fails" {
  run sh "$GEN" "$BATS_TEST_TMPDIR/f" nope
  [ "$status" -eq 1 ]
}
