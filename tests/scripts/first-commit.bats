#!/usr/bin/env bats

load helpers

FC="$ROOT/skills/groma/scripts/first-commit.sh"

setup() {
  export GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  P="$BATS_TEST_TMPDIR/app"
  mkdir -p "$P/docs"
  echo '# App' > "$P/README.md"
  echo '# Docs' > "$P/docs/README.md"
  git -C "$P" init -q -b main
}

identity() {
  git -C "$P" config user.name "groma-test"
  git -C "$P" config user.email "test@groma.invalid"
  git -C "$P" config commit.gpgsign false
}

@test "with identity: one commit with the fixed message, clean tree" {
  identity
  run sh "$FC" "$P" 9.9.9
  [ "$status" -eq 0 ]
  assert_output_contains "commit	done	"
  [ "$(git -C "$P" rev-list --count HEAD)" -eq 1 ]
  [ "$(git -C "$P" log -1 --format=%s)" = "chore: set up project with groma 9.9.9" ]
  [ -z "$(git -C "$P" status --porcelain)" ]
  git -C "$P" ls-files --error-unmatch docs/README.md
}

@test "without identity: no commit, the next action names the commands" {
  run sh "$FC" "$P" 9.9.9
  [ "$status" -eq 3 ]
  assert_output_contains "commit	no-identity"
  assert_output_contains "git config user.name"
  assert_output_contains "git config user.email"
  ! git -C "$P" rev-parse -q --verify HEAD
}

@test "repository with history: no commit" {
  identity
  commit_at "$P" 2026-11-01 first
  echo new > "$P/new.txt"
  run sh "$FC" "$P" 9.9.9
  [ "$status" -eq 0 ]
  [ "$output" = "commit	skipped	repository has commits" ]
  [ "$(git -C "$P" rev-list --count HEAD)" -eq 1 ]
}

@test ".gitignore is honoured" {
  identity
  mkdir -p "$P/node_modules/x"
  echo x > "$P/node_modules/x/index.js"
  echo 'node_modules/' > "$P/.gitignore"
  run sh "$FC" "$P" 9.9.9
  [ "$status" -eq 0 ]
  [ -z "$(git -C "$P" ls-files node_modules)" ]
  git -C "$P" ls-files --error-unmatch .gitignore
}

@test "a project inside a parent repository without commits commits only its own folder" {
  H="$BATS_TEST_TMPDIR/home"
  make_repo "$H"
  echo private > "$H/private.txt"
  mkdir -p "$H/work/app"
  echo '# App' > "$H/work/app/README.md"
  run sh "$FC" "$H/work/app" 9.9.9
  [ "$status" -eq 0 ]
  [ "$(git -C "$H" ls-files)" = "work/app/README.md" ]
}

@test "not a repository exits 1, usage errors exit 2" {
  rm -rf "$P/.git"
  run sh "$FC" "$P" 9.9.9
  [ "$status" -eq 1 ]
  run sh "$FC" "$P"
  [ "$status" -eq 2 ]
}

@test "files staged outside the project folder stay out of the first commit" {
  H="$BATS_TEST_TMPDIR/home"
  make_repo "$H"
  echo secret > "$H/secret"
  git -C "$H" add secret
  mkdir -p "$H/work/app"
  echo '# App' > "$H/work/app/README.md"
  run sh "$FC" "$H/work/app" 9.9.9
  [ "$status" -eq 0 ]
  [ "$(git -C "$H" ls-tree -r --name-only HEAD)" = "work/app/README.md" ]
}
