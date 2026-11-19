#!/usr/bin/env bats

load helpers

GI="$ROOT/skills/groma/scripts/git-init.sh"

# No repository above the test folder, no global or system git config.
setup() {
  export GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  P="$BATS_TEST_TMPDIR/app"
  mkdir -p "$P"
}

@test "empty folder outside git: state none, init recommended" {
  run sh "$GI" --check "$P"
  [ "$status" -eq 0 ]
  [ "$output" = "state	none	recommend=init" ]
  [ ! -e "$P/.git" ]
}

@test "brownfield folder outside git: skip recommended" {
  echo 'print(1)' > "$P/main.py"
  run sh "$GI" --check --type brownfield "$P"
  [ "$output" = "state	none	recommend=skip" ]
}

@test "project is the top level of a repository: state repo" {
  make_repo "$P"
  run sh "$GI" --check "$P"
  [ "$output" = "state	repo	$(cd "$P" && pwd -P)" ]
}

@test "parent work tree is named, using it is recommended" {
  H="$BATS_TEST_TMPDIR/home"
  make_repo "$H"
  mkdir -p "$H/work/app"
  run sh "$GI" --check "$H/work/app"
  [ "$output" = "state	parent	$(cd "$H" && pwd -P)	recommend=use" ]
}

@test "yes: repository on main with a .gitignore from the all rows" {
  run sh "$GI" "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "init	"
  assert_output_contains "gitignore=written"
  [ "$(git -C "$P" symbolic-ref --short HEAD)" = main ]
  grep -qxF '.DS_Store' "$P/.gitignore"
  ! grep -qxF 'node_modules/' "$P/.gitignore"
}

@test "named stack and detected manifest add their rows" {
  touch "$P/Cargo.toml"
  run sh "$GI" --stack 'Node, Go' "$P"
  [ "$status" -eq 0 ]
  grep -qxF 'node_modules/' "$P/.gitignore"
  grep -qxF 'target/' "$P/.gitignore"
  grep -qxF 'Thumbs.db' "$P/.gitignore"
  ! grep -qxF '__pycache__/' "$P/.gitignore"
}

@test "an existing .gitignore stays byte-identical" {
  printf 'secret\n' > "$P/.gitignore"
  cp "$P/.gitignore" "$BATS_TEST_TMPDIR/before"
  run sh "$GI" "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "gitignore=kept"
  cmp "$P/.gitignore" "$BATS_TEST_TMPDIR/before"
}

@test "no question means no repository: refuses an existing repository" {
  make_repo "$P"
  run sh "$GI" "$P"
  [ "$status" -eq 1 ]
}

@test "git without -b: falls back to symbolic-ref" {
  real=$(command -v git)
  bin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$bin"
  cat > "$bin/git" <<EOF
#!/bin/sh
for a in "\$@"; do [ "\$a" = -b ] && { echo "error: unknown switch 'b'" >&2; exit 129; }; done
exec "$real" "\$@"
EOF
  chmod +x "$bin/git"
  PATH="$bin:$PATH" run sh "$GI" "$P"
  [ "$status" -eq 0 ]
  [ "$(git -C "$P" symbolic-ref --short HEAD)" = main ]
}

@test "usage errors exit 2" {
  run sh "$GI"
  [ "$status" -eq 2 ]
  run sh "$GI" --type other "$P"
  [ "$status" -eq 2 ]
}

@test "missing ignore table: no repository, exit 1" {
  cp -R "$ROOT/skills/groma/scripts" "$BATS_TEST_TMPDIR/s"
  run sh "$BATS_TEST_TMPDIR/s/git-init.sh" "$P"
  [ "$status" -eq 1 ]
  [ ! -e "$P/.git" ]
}
