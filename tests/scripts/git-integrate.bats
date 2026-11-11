#!/usr/bin/env bats

# The integration procedure of git.integrate (design D2) and its safety rules (D3),
# run exactly as skills/groma-agents/references/git-strategies.md documents it:
# preflight (clean trees, refs recorded, main fetched and fast-forwarded), the row's
# commands (in the main branch's worktree when main is checked out elsewhere),
# conflicts aborted, other failures stopped without an abort. The helpers below are
# the procedure; the commands come from the table, so the table stays the tested
# source that groma-agents renders into AGENTS.md and groma-loop runs.

load helpers

TABLE="$ROOT/skills/groma-agents/references/git-strategies.md"
MAIN=main
BR=c007-cache

# backtick commands of a strategy's column (3 commands, 4 abort), placeholders resolved
table_commands() { # strategy column
  awk -F'|' -v s="$1" -v c="$2" '$2 ~ "^ *" s " *$" { n = split($c, a, "`"); for (i = 2; i <= n; i += 2) print a[i] }' "$TABLE" \
    | sed -e "s/<main>/$MAIN/g" -e "s/<branch>/$BR/g" -e "s|<message file>|$MSG|g"
}

# the other worktree that has <main> checked out, empty when it is this one
main_worktree() { # repo
  top=$(git -C "$1" rev-parse --show-toplevel)
  git -C "$1" worktree list --porcelain \
    | awk -v b="refs/heads/$MAIN" '/^worktree / { p = substr($0, 10) } $0 == "branch " b { print p }' \
    | grep -vx "$top" || true
}

# run one command of a row in repo $R; main-side commands go to $WT when set
run_cmd() { # command
  cmd=$1
  if [ -n "$WT" ]; then
    case "$cmd" in
      "git switch $MAIN"|"git switch $BR") return 0 ;;
      "git rebase "*) ;;
      *) cmd="git -C \"$WT\" ${cmd#git }" ;;
    esac
  fi
  OUT=$(cd "$R" && eval "$cmd" 2>&1)
}

# preflight: 0 ok, 1 escalate (reason in $PRE)
preflight() {
  PRE=""
  git -C "$R" symbolic-ref -q --short HEAD >/dev/null || { PRE="detached HEAD"; return 1; }
  [ -z "$(git -C "$R" status --porcelain)" ] || { PRE="working tree not clean"; return 1; }
  WT=$(main_worktree "$R")
  if [ -n "$WT" ]; then
    [ -z "$(git -C "$WT" status --porcelain)" ] || { PRE="worktree of $MAIN not clean: $WT"; return 1; }
  fi
  if [ -n "$(git -C "$R" remote)" ]; then
    git -C "$R" fetch -q
    if git -C "$R" rev-parse -q --verify "$MAIN@{u}" >/dev/null; then
      behind=$(git -C "$R" rev-list --count "$MAIN..$MAIN@{u}")
      ahead=$(git -C "$R" rev-list --count "$MAIN@{u}..$MAIN")
      if [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then PRE="$MAIN diverged from its upstream"; return 1; fi
      if [ "$behind" -gt 0 ]; then
        run_cmd "git switch $MAIN" && run_cmd "git merge --ff-only $MAIN@{u}" && run_cmd "git switch $BR" \
          || { PRE="fast-forward of $MAIN failed: $OUT"; return 1; }
      fi
    fi
  fi
  MAIN0=$(git -C "$R" rev-parse "refs/heads/$MAIN")
  BR0=$(git -C "$R" rev-parse "refs/heads/$BR")
}

# the row: 0 ok, 1 conflict (paths in $UPATHS), 2 other failure (git output in $OUT)
integrate() { # strategy
  UPATHS=""
  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    if ! run_cmd "$cmd"; then
      where=$R
      [ -n "$WT" ] && case "$cmd" in "git rebase "*) ;; *) where=$WT ;; esac
      UPATHS=$(git -C "$where" diff --name-only --diff-filter=U)
      [ -n "$UPATHS" ] && return 1
      return 2
    fi
  done <<EOF
$(table_commands "$1" 3)
EOF
}

abort() { # strategy
  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    run_cmd "$cmd" || return 1
  done <<EOF
$(table_commands "$1" 4)
EOF
}

# a conflict is aborted, anything else is left for the escalation
integrate_or_abort() { # strategy
  rc=0
  integrate "$1" || rc=$?
  [ "$rc" -eq 1 ] && abort "$1"
  return $rc
}

setup() {
  R="$BATS_TEST_TMPDIR/repo"
  WT=""
  MSG="$BATS_TEST_TMPDIR/msg"
  printf 'feat(c007-cache): add cache layer\n' > "$MSG"
  make_repo "$R"
  echo "base" > "$R/src.js"
  commit_at "$R" 2026-10-01 "feat: base"
  git -C "$R" switch -q -c "$BR"
  for i in 1 2 3 4 5; do
    echo "cache $i" >> "$R/cache.js"
    commit_at "$R" "2026-10-0$((i + 1))" "feat(c007-cache): cache step $i"
  done
  git -C "$R" switch -q "$MAIN"
  echo "main work" > "$R/other.js"
  commit_at "$R" 2026-10-10 "fix: other"
  git -C "$R" switch -q "$BR"
}

# a commit on main that conflicts with the branch's cache.js
make_conflict() {
  git -C "$R" switch -q "$MAIN"
  echo "conflict" > "$R/cache.js"
  commit_at "$R" 2026-10-11 "feat: conflicting cache"
  git -C "$R" switch -q "$BR"
}

refs_unchanged() {
  [ "$(git -C "$R" rev-parse "$MAIN")" = "$MAIN0" ]
  [ "$(git -C "$R" rev-parse "$BR")" = "$BR0" ]
  for d in "$R" ${WT:+"$WT"}; do
    [ ! -d "$(git -C "$d" rev-parse --git-path rebase-merge)" ]
    [ ! -d "$(git -C "$d" rev-parse --git-path rebase-apply)" ]
    [ ! -f "$(git -C "$d" rev-parse --git-path MERGE_HEAD)" ]
    [ -z "$(git -C "$d" status --porcelain)" ]
  done
}

on_branch() { # repo branch
  [ "$(git -C "$1" branch --show-current)" = "$2" ]
}

# --- the table --------------------------------------------------------------------

@test "the table lists rebase, merge and squash with commands and an abort" {
  for s in rebase merge squash; do
    [ -n "$(table_commands $s 3)" ]
    [ -n "$(table_commands $s 4)" ]
  done
}

@test "the merge and squash aborts return to the branch" {
  table_commands merge 4 | grep -qx "git switch $BR"
  table_commands squash 4 | grep -qx "git switch $BR"
}

@test "no cell forces, deletes a branch, moves main by hand or pushes; the rules forbid it" {
  cells=$(awk -F'|' '/^\| (rebase|merge|squash) \|/ { print $3 $4 }' "$TABLE")
  ! printf '%s\n' "$cells" | grep -Eq -- '--force|branch -[dDf]|update-ref|reset --hard|push'
  grep -q 'git branch -f' "$TABLE"
  grep -q 'git update-ref' "$TABLE"
  grep -q 'reset --hard' "$TABLE"
  grep -q -- '--force-with-lease' "$TABLE"
}

@test "the squash commit reads its message from a file" {
  table_commands squash 3 | grep -q "git commit -F "
  ! table_commands squash 3 | grep -q 'commit -m'
}

# --- happy paths --------------------------------------------------------------------

@test "rebase: main is fast-forwarded to the rebased branch, no merge commit" {
  preflight
  integrate rebase
  [ "$(git -C "$R" rev-parse "$MAIN")" = "$(git -C "$R" rev-parse "$BR")" ]
  [ "$(git -C "$R" rev-list --merges --count "$MAIN")" -eq 0 ]
  [ "$(git -C "$R" rev-list --count "$MAIN0..$MAIN")" -eq 5 ]
  git -C "$R" merge-base --is-ancestor "$MAIN0" "$MAIN"
  [ "$(git -C "$R" branch --list "$BR" | wc -l | tr -d ' ')" -eq 1 ]
  on_branch "$R" "$MAIN"
}

@test "merge: one merge commit whose parents are the old main and the branch tip" {
  preflight
  integrate merge
  [ "$(git -C "$R" rev-list --merges --count "$MAIN0..$MAIN")" -eq 1 ]
  [ "$(git -C "$R" rev-parse "$MAIN^1")" = "$MAIN0" ]
  [ "$(git -C "$R" rev-parse "$MAIN^2")" = "$BR0" ]
  [ "$(git -C "$R" rev-parse "$BR")" = "$BR0" ]
  on_branch "$R" "$MAIN"
}

@test "squash: main gains one commit named after the change, the branch keeps its five" {
  preflight
  integrate squash
  [ "$(git -C "$R" rev-list --count "$MAIN0..$MAIN")" -eq 1 ]
  [ "$(git -C "$R" rev-list --merges --count "$MAIN")" -eq 0 ]
  run git -C "$R" log -1 --format=%s "$MAIN"
  assert_output_contains "feat(c007-cache): add cache layer"
  [ "$(git -C "$R" rev-parse "$BR")" = "$BR0" ]
  [ "$(git -C "$R" rev-list --count "$MAIN0..$BR")" -eq 5 ]
  on_branch "$R" "$MAIN"
}

@test "rebase never touches commits that are already on main" {
  preflight
  integrate rebase
  git -C "$R" merge-base --is-ancestor "$MAIN0" "$MAIN"
  run git -C "$R" log --format=%s "$MAIN0"
  assert_output_contains "fix: other"
}

# --- conflicts: abort, refs unchanged, back on the branch -----------------------------

@test "rebase conflict: the abort leaves both branches as before, on the branch" {
  make_conflict
  preflight
  ! integrate_or_abort rebase
  case "$UPATHS" in *cache.js*) ;; *) false ;; esac
  refs_unchanged
  on_branch "$R" "$BR"
}

@test "merge conflict: the abort leaves both branches as before, on the branch" {
  make_conflict
  preflight
  ! integrate_or_abort merge
  case "$UPATHS" in *cache.js*) ;; *) false ;; esac
  refs_unchanged
  on_branch "$R" "$BR"
}

@test "squash conflict: the abort leaves both branches as before, on the branch" {
  make_conflict
  preflight
  ! integrate_or_abort squash
  case "$UPATHS" in *cache.js*) ;; *) false ;; esac
  refs_unchanged
  on_branch "$R" "$BR"
}

# --- preflight: nothing runs on a dirty tree or a detached HEAD -----------------------

@test "dirty tracked file: preflight escalates before any command" {
  echo "dirty" >> "$R/src.js"
  main_before=$(git -C "$R" rev-parse "$MAIN")
  ! preflight
  [ "$PRE" = "working tree not clean" ]
  [ "$(git -C "$R" rev-parse "$MAIN")" = "$main_before" ]
  on_branch "$R" "$BR"
}

@test "staged file: preflight escalates, so squash never commits it" {
  echo "staged" >> "$R/src.js"
  git -C "$R" add src.js
  ! preflight
  [ "$PRE" = "working tree not clean" ]
}

@test "detached HEAD: preflight escalates" {
  git -C "$R" switch -q --detach HEAD
  ! preflight
  [ "$PRE" = "detached HEAD" ]
}

# --- failures without conflicts: stop, no abort ---------------------------------------

@test "already integrated: squash fails with nothing to commit, no abort, main unchanged" {
  preflight
  integrate rebase
  git -C "$R" switch -q "$BR"
  preflight
  rc=0
  integrate squash || rc=$?
  [ "$rc" -eq 2 ]
  [ -z "$UPATHS" ]
  case "$OUT" in *"nothing to commit"*|*"Already up to date"*) ;; *) echo "$OUT"; false ;; esac
  [ "$(git -C "$R" rev-parse "$MAIN")" = "$MAIN0" ]
  [ -z "$(git -C "$R" status --porcelain)" ]
}

# --- linked worktrees: main checked out elsewhere -------------------------------------

@test "main checked out in another worktree: main-side commands run there" {
  W="$BATS_TEST_TMPDIR/wt-branch"
  git -C "$R" switch -q "$MAIN"
  git -C "$R" worktree add -q "$W" "$BR"
  MAINREPO=$R
  R=$W
  preflight
  [ "$WT" = "$(git -C "$MAINREPO" rev-parse --show-toplevel)" ]
  integrate rebase
  [ "$(git -C "$R" rev-parse "$MAIN")" = "$(git -C "$R" rev-parse "$BR")" ]
  [ "$(git -C "$R" rev-list --merges --count "$MAIN")" -eq 0 ]
  on_branch "$MAINREPO" "$MAIN"
  on_branch "$W" "$BR"
  [ -z "$(git -C "$MAINREPO" status --porcelain)" ]
}

@test "main checked out in another worktree: conflicts abort there, both trees clean" {
  W="$BATS_TEST_TMPDIR/wt-branch"
  make_conflict
  git -C "$R" switch -q "$MAIN"
  git -C "$R" worktree add -q "$W" "$BR"
  MAINREPO=$R
  R=$W
  for s in merge squash rebase; do
    preflight
    ! integrate_or_abort "$s"
    case "$UPATHS" in *cache.js*) ;; *) false ;; esac
    refs_unchanged
    on_branch "$MAINREPO" "$MAIN"
    on_branch "$W" "$BR"
  done
}

@test "main checked out in a dirty worktree: preflight escalates" {
  W="$BATS_TEST_TMPDIR/wt-branch"
  git -C "$R" switch -q "$MAIN"
  git -C "$R" worktree add -q "$W" "$BR"
  echo "dirty" >> "$R/src.js"
  MAINREPO=$R
  R=$W
  ! preflight
  case "$PRE" in "worktree of main not clean"*) ;; *) echo "$PRE"; false ;; esac
}

# --- stale main: fetch and fast-forward before integrating ----------------------------

with_remote() {
  BARE="$BATS_TEST_TMPDIR/remote.git"
  git -C "$R" switch -q "$MAIN"
  git clone -q --bare "$R" "$BARE"
  git -C "$R" switch -q "$BR"
  git -C "$R" remote add origin "$BARE"
  git -C "$R" fetch -q origin
  git -C "$R" branch -q -u origin/main main
  git -C "$R" remote set-head origin main
  O="$BATS_TEST_TMPDIR/other"
  git clone -q "$BARE" "$O"
  git -C "$O" config user.name other
  git -C "$O" config user.email other@groma.invalid
  git -C "$O" config commit.gpgsign false
  echo "remote work" > "$O/r.js"
  git -C "$O" add r.js
  commit_at "$O" 2026-10-12 "feat: remote work"
  git -C "$O" push -q origin main
}

@test "main behind its upstream is fast-forwarded first, then the push succeeds" {
  with_remote
  preflight
  [ "$(git -C "$R" rev-list --count "$MAIN..$MAIN@{u}")" -eq 0 ]
  integrate rebase
  run git -C "$R" log --format=%s "$MAIN"
  assert_output_contains "feat: remote work"
  assert_output_contains "feat(c007-cache): cache step 5"
  [ "$(git -C "$R" rev-list --merges --count "$MAIN")" -eq 0 ]
  git -C "$R" push -q
  [ "$(git -C "$BARE" rev-parse main)" = "$(git -C "$R" rev-parse "$MAIN")" ]
}

@test "main diverged from its upstream: preflight escalates" {
  with_remote
  git -C "$R" switch -q "$MAIN"
  echo "local" > "$R/l.js"
  git -C "$R" add l.js
  commit_at "$R" 2026-10-13 "feat: local only"
  git -C "$R" switch -q "$BR"
  ! preflight
  [ "$PRE" = "main diverged from its upstream" ]
}
