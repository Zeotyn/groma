#!/usr/bin/env bats

load helpers

GP="$ROOT/skills/groma-detect/scripts/git-practice.sh"

setup_file() {
  sh "$ROOT/tests/fixtures/histories.sh" "$BATS_FILE_TMPDIR/h" >/dev/null
  sh "$ROOT/tests/fixtures/generate.sh" "$BATS_FILE_TMPDIR/f" empty >/dev/null
}

H() { echo "$BATS_FILE_TMPDIR/h/$1"; }

# <dir> with <total> commits on main, the first <conventional> of them conventional
linear_repo() { # dir conventional total
  make_repo "$1"
  i=0
  while [ "$i" -lt "$3" ]; do
    i=$((i + 1))
    echo "$i" > "$1/notes.md"
    if [ "$i" -le "$2" ]; then m="feat: step $i"; else m="Step $i"; fi
    commit_at "$1" "2025-02-$(printf %02d "$i")" "$m"
  done
}

# <dir> with <n> pull-request merges on main
pr_repo() { # dir n
  make_repo "$1"
  echo start > "$1/notes.md"
  commit_at "$1" 2025-03-01 "Initial commit"
  i=0
  while [ "$i" -lt "$2" ]; do
    i=$((i + 1))
    git -C "$1" switch -q -c "pr-$i"
    echo "$i" >> "$1/notes.md"
    commit_at "$1" "2025-03-$(printf %02d $((i + 1)))" "Add thing $i"
    git -C "$1" switch -q main
    GIT_AUTHOR_DATE="2025-04-$(printf %02d "$i")T12:00:00Z" GIT_COMMITTER_DATE="2025-04-$(printf %02d "$i")T12:00:00Z" \
      git -C "$1" merge -q --no-ff -m "Merge pull request #$i from dev/pr-$i" "pr-$i"
  done
}

@test "histories script builds the three repositories" {
  for h in pr-merge squash linear-conventional; do
    [ -d "$(H $h)/.git" ]
  done
  [ "$(git -C "$(H pr-merge)" rev-list --merges --count main)" -eq 8 ]
  [ "$(git -C "$(H squash)" rev-list --merges --count main)" -eq 0 ]
  run sh "$ROOT/tests/fixtures/histories.sh" "$BATS_TEST_TMPDIR/x" nope
  [ "$status" -eq 1 ]
}

@test "pull-request merges recommend merge, with evidence" {
  run sh "$GP" "$(H pr-merge)"
  [ "$status" -eq 0 ]
  assert_output_contains "main	main"
  assert_output_contains "integrate	merge	7 of 8 merges are pull-request merges"
  assert_output_contains "summary	first_parent=10	merges=8	pr_merges=7	squash_subjects=0	commits=10	conventional=8"
}

@test "commit style counts the commits behind the merges" {
  run sh "$GP" "$(H pr-merge)"
  assert_output_contains "commits	conventional	8 of 10 subjects are conventional"
}

@test "subjects ending in (#n) without merges recommend squash" {
  run sh "$GP" "$(H squash)"
  [ "$status" -eq 0 ]
  assert_output_contains "integrate	squash	8 of 10 subjects end in (#n)"
  assert_output_contains "commits	conventional	8 of 10 subjects are conventional"
  assert_output_contains "squash_subjects=8"
}

@test "linear conventional history recommends rebase" {
  run sh "$GP" "$(H linear-conventional)"
  [ "$status" -eq 0 ]
  assert_output_contains "integrate	rebase	0 merges in 10 commits, 0 subjects end in (#n)"
  assert_output_contains "commits	conventional	9 of 10 subjects are conventional"
}

@test "70 percent conventional subjects is conventional, 60 percent is free" {
  linear_repo "$BATS_TEST_TMPDIR/seven" 7 10
  run sh "$GP" "$BATS_TEST_TMPDIR/seven"
  assert_output_contains "commits	conventional	7 of 10 subjects are conventional"
  linear_repo "$BATS_TEST_TMPDIR/six" 6 10
  run sh "$GP" "$BATS_TEST_TMPDIR/six"
  assert_output_contains "commits	free	6 of 10 subjects are conventional"
}

@test "fewer than 5 merges do not make a merge project" {
  pr_repo "$BATS_TEST_TMPDIR/few" 4
  run sh "$GP" "$BATS_TEST_TMPDIR/few"
  assert_output_contains "integrate	rebase	4 merges in 5 commits, 0 subjects end in (#n)"
  pr_repo "$BATS_TEST_TMPDIR/five" 5
  run sh "$GP" "$BATS_TEST_TMPDIR/five"
  assert_output_contains "integrate	merge	5 of 5 merges are pull-request merges"
}

@test "merges that are not pull-request merges do not make a merge project" {
  D="$BATS_TEST_TMPDIR/sync"
  make_repo "$D"
  echo start > "$D/notes.md"
  commit_at "$D" 2025-05-01 "Initial commit"
  for i in 1 2 3 4 5 6; do
    git -C "$D" switch -q -c "s-$i"
    echo "$i" >> "$D/notes.md"
    commit_at "$D" "2025-05-$(printf %02d $((i + 1)))" "Sync $i"
    git -C "$D" switch -q main
    GIT_AUTHOR_DATE="2025-06-0${i}T12:00:00Z" GIT_COMMITTER_DATE="2025-06-0${i}T12:00:00Z" \
      git -C "$D" merge -q --no-ff -m "Sync $i into main" "s-$i"
  done
  run sh "$GP" "$D"
  assert_output_contains "integrate	rebase	6 merges in 7 commits"
  assert_output_contains "merges=6	pr_merges=0"
}

@test "pull-request merges win over (#n) subjects" {
  D="$BATS_TEST_TMPDIR/both"
  pr_repo "$D" 6
  for i in 1 2 3 4 5 6 7 8; do
    echo "sq $i" >> "$D/notes.md"
    commit_at "$D" "2025-07-$(printf %02d "$i")" "feat: squashed $i (#1$i)"
  done
  run sh "$GP" "$D"
  assert_output_contains "integrate	merge	6 of 6 merges are pull-request merges"
  assert_output_contains "squash_subjects=8"
}

@test "main branch: master when there is no main" {
  D="$BATS_TEST_TMPDIR/master"
  mkdir -p "$D"
  git -C "$D" init -q -b master
  git -C "$D" config user.name t; git -C "$D" config user.email t@t.invalid; git -C "$D" config commit.gpgsign false
  echo x > "$D/notes.md"
  commit_at "$D" 2025-08-01 "feat: first"
  run sh "$GP" "$D"
  assert_output_contains "main	master"
  assert_output_contains "commits	conventional	1 of 1 subjects are conventional"
}

@test "main branch: the remote default branch wins" {
  D="$BATS_TEST_TMPDIR/trunk"
  mkdir -p "$D"
  git -C "$D" init -q -b trunk
  git -C "$D" config user.name t; git -C "$D" config user.email t@t.invalid; git -C "$D" config commit.gpgsign false
  echo x > "$D/notes.md"
  commit_at "$D" 2025-08-01 "feat: first"
  git clone -q --bare "$D" "$BATS_TEST_TMPDIR/remote.git"
  git -C "$D" remote add origin "$BATS_TEST_TMPDIR/remote.git"
  git -C "$D" fetch -q origin
  git -C "$D" remote set-head origin trunk
  git -C "$D" switch -q -c main
  echo y > "$D/notes.md"
  commit_at "$D" 2025-08-02 "Not conventional"
  run sh "$GP" "$D"
  assert_output_contains "main	trunk"
  assert_output_contains "commits	conventional	1 of 1 subjects are conventional"
}

@test "the analysis follows the main branch, not the checked-out branch" {
  D="$BATS_TEST_TMPDIR/wip"
  sh "$ROOT/tests/fixtures/histories.sh" "$BATS_TEST_TMPDIR/w" linear-conventional >/dev/null
  D="$BATS_TEST_TMPDIR/w/linear-conventional"
  git -C "$D" switch -q -c wip
  for i in 1 2 3 4 5; do
    echo "wip $i" >> "$D/notes.md"
    commit_at "$D" "2025-09-0$i" "wip $i"
  done
  run sh "$GP" "$D"
  assert_output_contains "main	main"
  assert_output_contains "integrate	rebase	0 merges in 10 commits"
  assert_output_contains "commits	conventional	9 of 10 subjects are conventional"
}

@test "empty repository prints the defaults with no history" {
  run sh "$GP" "$BATS_FILE_TMPDIR/f/empty"
  [ "$status" -eq 0 ]
  assert_output_contains "main	main"
  assert_output_contains "integrate	rebase	no history"
  assert_output_contains "commits	conventional	no history"
  assert_output_contains "summary	first_parent=0	merges=0	pr_merges=0	squash_subjects=0	commits=0	conventional=0"
}

@test "folder without git prints the defaults with no history" {
  mkdir -p "$BATS_TEST_TMPDIR/plain"
  run sh "$GP" "$BATS_TEST_TMPDIR/plain"
  [ "$status" -eq 0 ]
  assert_output_contains "integrate	rebase	no history"
}

@test "defaults to the current directory" {
  cd "$(H squash)"
  run sh "$GP"
  assert_output_contains "integrate	squash"
}

@test "missing directory exits 2" {
  run sh "$GP" "$BATS_TEST_TMPDIR/nope"
  [ "$status" -eq 2 ]
}

@test "is read-only" {
  sh "$GP" "$(H pr-merge)" >/dev/null
  [ -z "$(git -C "$(H pr-merge)" status --porcelain)" ]
  [ "$(git -C "$(H pr-merge)" branch --show-current)" = main ]
}
