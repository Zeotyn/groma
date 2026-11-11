#!/usr/bin/env bats

# The integration sequences of git.integrate (design D2) and the abort rule (D3).
# The commands come from the strategies table that groma-agents renders into
# AGENTS.md and groma-loop runs at archive, so the table stays the tested source.

load helpers

TABLE="$ROOT/skills/groma-agents/references/git-strategies.md"

# commands of one strategy, one per line, placeholders resolved for this test
strategy_commands() { # strategy
  awk -F'|' -v s="$1" '$2 ~ "^ *" s " *$" { n = split($3, a, "`"); for (i = 2; i <= n; i += 2) print a[i] }' "$TABLE" \
    | sed -e 's/<main>/main/g' -e 's/<branch>/c007-cache/g' \
          -e 's/<type>(<change-id>): <proposal title>/feat(c007-cache): add cache layer/'
}

abort_command() { # strategy
  awk -F'|' -v s="$1" '$2 ~ "^ *" s " *$" { n = split($4, a, "`"); print a[2] }' "$TABLE"
}

# run the strategy's commands in $R in order; stop at the first failure
integrate() { # strategy
  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    (cd "$R" && eval "$cmd" >/dev/null 2>&1) || return 1
  done <<EOF
$(strategy_commands "$1")
EOF
}

setup() {
  R="$BATS_TEST_TMPDIR/repo"
  make_repo "$R"
  echo "base" > "$R/src.js"
  commit_at "$R" 2026-10-01 "feat: base"
  git -C "$R" switch -q -c c007-cache
  for i in 1 2 3 4 5; do
    echo "cache $i" >> "$R/cache.js"
    commit_at "$R" "2026-10-0$((i + 1))" "feat(c007-cache): cache step $i"
  done
  git -C "$R" switch -q main
  echo "main work" > "$R/other.js"
  commit_at "$R" 2026-10-10 "fix: other"
  MAIN0=$(git -C "$R" rev-parse main)
  BR0=$(git -C "$R" rev-parse c007-cache)
}

# a commit on main that conflicts with the branch's cache.js
make_conflict() {
  git -C "$R" switch -q main
  echo "conflict" > "$R/cache.js"
  commit_at "$R" 2026-10-11 "feat: conflicting cache"
  MAIN0=$(git -C "$R" rev-parse main)
}

refs_unchanged() {
  [ "$(git -C "$R" rev-parse main)" = "$MAIN0" ]
  [ "$(git -C "$R" rev-parse c007-cache)" = "$BR0" ]
  [ ! -d "$R/.git/rebase-merge" ]
  [ ! -d "$R/.git/rebase-apply" ]
  [ ! -f "$R/.git/MERGE_HEAD" ]
  [ -z "$(git -C "$R" status --porcelain)" ]
}

@test "the table lists rebase, merge and squash with commands and an abort command" {
  for s in rebase merge squash; do
    [ -n "$(strategy_commands $s)" ]
    [ -n "$(abort_command $s)" ]
  done
  # no command cell forces, deletes a branch or pushes
  cells=$(awk -F'|' '/^\| (rebase|merge|squash) \|/ { print $3 $4 }' "$TABLE")
  ! printf '%s\n' "$cells" | grep -Eq -- '--force|branch -[dD]|push'
}

@test "rebase: main is fast-forwarded to the rebased branch, no merge commit" {
  integrate rebase
  [ "$(git -C "$R" rev-parse main)" = "$(git -C "$R" rev-parse c007-cache)" ]
  [ "$(git -C "$R" rev-list --merges --count main)" -eq 0 ]
  [ "$(git -C "$R" rev-list --count "$MAIN0..main")" -eq 5 ]
  git -C "$R" merge-base --is-ancestor "$MAIN0" main
  [ "$(git -C "$R" branch --list c007-cache | wc -l | tr -d ' ')" -eq 1 ]
  [ "$(git -C "$R" branch --show-current)" = main ]
}

@test "merge: one merge commit whose parents are the old main and the branch tip" {
  integrate merge
  [ "$(git -C "$R" rev-list --merges --count "$MAIN0..main")" -eq 1 ]
  [ "$(git -C "$R" rev-parse main^1)" = "$MAIN0" ]
  [ "$(git -C "$R" rev-parse main^2)" = "$BR0" ]
  [ "$(git -C "$R" rev-parse c007-cache)" = "$BR0" ]
}

@test "squash: main gains one commit named after the change, the branch keeps its five" {
  integrate squash
  [ "$(git -C "$R" rev-list --count "$MAIN0..main")" -eq 1 ]
  [ "$(git -C "$R" rev-list --merges --count main)" -eq 0 ]
  run git -C "$R" log -1 --format=%s main
  assert_output_contains "feat(c007-cache): add cache layer"
  [ "$(git -C "$R" rev-parse c007-cache)" = "$BR0" ]
  [ "$(git -C "$R" rev-list --count "$MAIN0..c007-cache")" -eq 5 ]
}

@test "rebase conflict: the abort leaves both branches as before and the path is known" {
  make_conflict
  ! integrate rebase
  run git -C "$R" diff --name-only --diff-filter=U
  assert_output_contains "cache.js"
  (cd "$R" && eval "$(abort_command rebase)")
  refs_unchanged
}

@test "merge conflict: the abort leaves both branches as before" {
  make_conflict
  ! integrate merge
  run git -C "$R" diff --name-only --diff-filter=U
  assert_output_contains "cache.js"
  (cd "$R" && eval "$(abort_command merge)")
  refs_unchanged
}

@test "squash conflict: the abort leaves both branches as before" {
  make_conflict
  ! integrate squash
  run git -C "$R" diff --name-only --diff-filter=U
  assert_output_contains "cache.js"
  (cd "$R" && eval "$(abort_command squash)")
  refs_unchanged
}

@test "rebase never touches commits that are already on main" {
  integrate rebase
  git -C "$R" merge-base --is-ancestor "$MAIN0" main
  [ "$(git -C "$R" rev-parse "$MAIN0")" = "$MAIN0" ]
  run git -C "$R" log --format=%s "$MAIN0"
  assert_output_contains "fix: other"
}
