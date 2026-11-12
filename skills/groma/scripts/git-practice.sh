#!/bin/sh
# Recommend the git settings of .groma/config.yaml from a repository's history. Read-only.
#
# Usage: git-practice.sh [dir]
#
# Main branch (the rule of groma-agents/references/git-strategies.md): the remote's
# default branch, else main, else master, else a remote-only origin/main, else the
# current branch (HEAD when detached). A name without a local branch is read
# through refs/remotes/origin/<main>.
#
# Reads the last 200 first-parent commits of the main branch for the integration
# strategy, and the last 200 non-merge commits of that branch for the commit style.
#
# Rules, in order:
#   merge   at least 5 merge commits, and at least half of them start with
#           "Merge pull request" or "Merge branch" (not "Merge branch 'x' of <url>",
#           which is a pull)
#   squash  at least half of the first-parent subjects end in (#<n>), fewer than 5 merges
#   rebase  otherwise
#   commits: conventional when at least 70 percent of the non-merge subjects match
#            ^(feat|fix|docs|chore|refactor|test|ci|build|perf|style|revert)(\(.+\))?!?:
# Fewer than 10 commits of a kind give that kind's default, with the counts.
#
# Output, tab-separated:
#   main<TAB><branch>
#   integrate<TAB>rebase|merge|squash<TAB><evidence>
#   commits<TAB>conventional|free<TAB><evidence>
#   summary<TAB>first_parent=<n><TAB>merges=<n><TAB>pr_merges=<n><TAB>squash_subjects=<n><TAB>commits=<n><TAB>conventional=<n>
# Without commits (or outside git) the defaults are printed with the evidence "no history".
# Exit 0; a missing directory exits 2.
set -eu

DIR=${1:-.}
[ -d "$DIR" ] || { echo "not a directory: $DIR" >&2; exit 2; }
TAB=$(printf '\t')
CONV_RE='^(feat|fix|docs|chore|refactor|test|ci|build|perf|style|revert)(\(.+\))?!?: '

g() { git -C "$DIR" "$@"; }
has_ref() { g rev-parse -q --verify "$1^{commit}" >/dev/null 2>&1; }

MAIN=main
REF=""
if g rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  m=$(g symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)
  m=${m#origin/}
  if [ -n "$m" ]; then
    MAIN=$m
    if has_ref "refs/heads/$m"; then REF="refs/heads/$m"
    elif has_ref "refs/remotes/origin/$m"; then REF="refs/remotes/origin/$m"
    fi
  elif has_ref refs/heads/main; then MAIN=main; REF=refs/heads/main
  elif has_ref refs/heads/master; then MAIN=master; REF=refs/heads/master
  elif has_ref refs/remotes/origin/main; then MAIN=main; REF=refs/remotes/origin/main
  else
    cur=$(g symbolic-ref -q --short HEAD 2>/dev/null || true)
    if [ -n "$cur" ] && has_ref "refs/heads/$cur"; then MAIN=$cur; REF="refs/heads/$cur"
    elif [ -z "$cur" ] && has_ref HEAD; then MAIN=HEAD; REF=HEAD
    elif [ -n "$cur" ]; then MAIN=$cur
    fi
  fi
fi
printf 'main%s%s\n' "$TAB" "$MAIN"

if [ -z "$REF" ]; then
  printf 'integrate%srebase%sno history\n' "$TAB" "$TAB"
  printf 'commits%sconventional%sno history\n' "$TAB" "$TAB"
  printf 'summary%sfirst_parent=0%smerges=0%spr_merges=0%ssquash_subjects=0%scommits=0%sconventional=0\n' \
    "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
  exit 0
fi

# non-merge commits: the subjects behind the merges tell the commit style
subjects=$(g log --no-merges -200 --format=%s "$REF" --)
commits=$(printf '%s\n' "$subjects" | grep -c . || true)
conventional=$(printf '%s\n' "$subjects" | grep -Ec "$CONV_RE" || true)

# first-parent commits: parents<TAB>subject
g log --first-parent -200 --format='%P%x09%s' "$REF" -- | awk -F "$TAB" \
  -v commits="$commits" -v conventional="$conventional" '
  NF {
    first++
    np = split($1, p, " ")
    s = $0; sub(/^[^\t]*\t/, "", s)
    if (np > 1) {
      merges++
      if (s ~ /^Merge pull request / || (s ~ /^Merge branch / && s !~ /^Merge branch \047[^\047]+\047 of /)) pr++
    }
    if (s ~ /\(#[0-9]+\)$/) squash++
  }
  END {
    first += 0; merges += 0; pr += 0; squash += 0
    few = ", fewer than 10 commits: default"
    if (first < 10)
      printf "integrate\trebase\t%d merges in %d commits, %d subjects end in (#n)%s\n", merges, first, squash, few
    else if (merges >= 5 && pr * 2 >= merges)
      printf "integrate\tmerge\t%d of %d merges are pull-request merges\n", pr, merges
    else if (squash * 2 >= first && merges < 5)
      printf "integrate\tsquash\t%d of %d subjects end in (#n)\n", squash, first
    else
      printf "integrate\trebase\t%d merges in %d commits, %d subjects end in (#n)\n", merges, first, squash
    if (commits < 10)
      printf "commits\tconventional\t%d of %d subjects are conventional%s\n", conventional, commits, few
    else
      printf "commits\t%s\t%d of %d subjects are conventional\n", (conventional * 100 >= commits * 70) ? "conventional" : "free", conventional, commits
    printf "summary\tfirst_parent=%d\tmerges=%d\tpr_merges=%d\tsquash_subjects=%d\tcommits=%d\tconventional=%d\n",
      first, merges, pr, squash, commits, conventional
  }'
