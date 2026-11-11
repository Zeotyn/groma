#!/bin/sh
# Docs impact of a change. Read-only.
#
# Usage: docs-impact.sh [--root <project>] [--base <ref>] [--docs <docs-dir>] [--gate] <change-dir>
#
# Changed paths: `git diff <base>` (committed and uncommitted) plus untracked
# files, without the change folder itself. The base defaults to
# `git merge-base <main> HEAD` when the current branch is named after the
# change (the main branch: the remote's default branch, else main, else
# master); otherwise to the parent of the commit that added
# <change-dir>/proposal.md; without that commit the working tree is compared
# with HEAD (both announced by a `note` line).
#
# (a) impact: a non-ADR doc whose frontmatter `sources` prefix-match a changed
#     path while the doc itself is unchanged. Sources inside the docs dir are
#     ignored. A tasks.md line `Docs: <path> unchanged, because <reason>`
#     clears <path>.
# (b) adr: a decision `### D<n>: <title>` in <change-dir>/design.md that needs
#     an ADR and has none with frontmatter `origin: <change>#D<n>`.
#     docs.adr_from in .groma/config.yaml: design-alternatives (default, a
#     line starting with "Alternatives" in the decision), marked (a line
#     `ADR: yes`), off.
#
# Output, tab-separated:
#   note<TAB><text>
#   impact<TAB><doc><TAB><changed paths, space-separated>
#   adr<TAB><change>#D<n><TAB><title>
#   summary<TAB>impact=<n><TAB>adr=<n>
# Exit 0; with --gate exit 4 when impact or adr is not 0. Usage errors exit 2.
set -eu

ROOT=. BASE="" DOCS=docs GATE=0 CHANGE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=$2; shift 2 ;;
    --base) BASE=$2; shift 2 ;;
    --docs) DOCS=$2; shift 2 ;;
    --gate) GATE=1; shift ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) CHANGE=$1; shift ;;
  esac
done
[ -n "$CHANGE" ] || { echo "usage: docs-impact.sh [--root <dir>] [--base <ref>] [--gate] <change-dir>" >&2; exit 2; }
case "$CHANGE" in /*) ;; *) [ -d "$CHANGE" ] || CHANGE="$ROOT/$CHANGE" ;; esac
[ -d "$CHANGE" ] || { echo "not a change folder: $CHANGE" >&2; exit 2; }
CHANGE=$(CDPATH='' cd -- "$CHANGE" && pwd -P)
cd "$ROOT"
ROOT=$(pwd -P)
git rev-parse HEAD >/dev/null 2>&1 || { echo "not a git repository with commits: $ROOT" >&2; exit 2; }
REL=${CHANGE#"$ROOT"/}
NAME=${CHANGE##*/}
DOCS=${DOCS#./}; DOCS=${DOCS%/}
TAB=$(printf '\t')

has_ref() { git rev-parse -q --verify "$1^{commit}" >/dev/null 2>&1; }
# main branch per groma-agents/references/git-strategies.md: the remote's default
# branch, else main, else master, else a remote-only origin/main; empty when none
main_branch() {
  m=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)
  m=${m#origin/}
  [ -n "$m" ] || ! has_ref refs/heads/main || m=main
  [ -n "$m" ] || ! has_ref refs/heads/master || m=master
  [ -n "$m" ] || ! has_ref refs/remotes/origin/main || m=main
  echo "$m"
}
# the ref to read a branch name through: local first, else the remote's copy
ref_of() {
  if has_ref "refs/heads/$1"; then echo "refs/heads/$1"
  elif has_ref "refs/remotes/origin/$1"; then echo "refs/remotes/origin/$1"
  fi
}

if [ -z "$BASE" ]; then
  branch=$(git symbolic-ref -q --short HEAD 2>/dev/null || true)
  main=$(main_branch)
  if [ "$branch" = "$NAME" ] && [ -n "$main" ] && [ "$main" != "$branch" ]; then
    # on the change branch: everything since it left the main branch; unrelated
    # histories (an orphan branch) have no merge base and keep the fallback below
    ref=$(ref_of "$main")
    [ -z "$ref" ] || BASE=$(git merge-base "$ref" HEAD 2>/dev/null) || BASE=""
    [ -z "$BASE" ] || printf 'note%son branch %s, comparing with its merge base with %s (%s)\n' "$TAB" "$branch" "$main" "$(git rev-parse --short "$BASE")"
  fi
fi
if [ -z "$BASE" ]; then
  added=$(git log --diff-filter=A --format=%H -- "$REL/proposal.md" | tail -n 1)
  if [ -z "$added" ]; then
    BASE=HEAD
    printf 'note%sproposal not committed, comparing the working tree with HEAD\n' "$TAB"
  else
    # root commit has no parent: compare with the empty tree
    BASE=$(git rev-parse -q --verify "$added^" || git hash-object -t tree /dev/null)
  fi
elif ! git rev-parse -q --verify "$BASE^{commit}" >/dev/null; then
  echo "unknown base: $BASE" >&2; exit 2
fi

# newline-separated lists from here on: no word splitting on spaces, no globbing
set -f
NL='
'
IFS=$NL
CHANGED=$( { git -c core.quotePath=false diff --relative --no-renames --name-only "$BASE" -- .
  git -c core.quotePath=false ls-files --others --exclude-standard; } | LC_ALL=C sort -u)
CHANGED=$(printf '%s\n' "$CHANGED" | grep -v "^$REL/" || true)

# frontmatter value for key, empty if absent
fm_get() {
  awk -v k="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 && index($0, k ":") == 1 {
      v = substr($0, length(k) + 2); gsub(/^[ \t"'\'']+|[ \t"'\'']+$/, "", v); print v; exit
    }' "$1"
}

# frontmatter list for `sources`, one per line; supports [a, b] and block lists
fm_sources() {
  awk '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 && inlist {
      if ($0 ~ /^[ \t]*-[ \t]*/) { v = $0; sub(/^[ \t]*-[ \t]*/, "", v); gsub(/["'\'']/, "", v); gsub(/[ \t]+$/, "", v); if (v != "") print v; next }
      inlist = 0
    }
    NR > 1 && /^sources:/ {
      v = substr($0, 9); gsub(/^[ \t]+|[ \t]+$/, "", v)
      if (v == "") { inlist = 1; next }
      gsub(/^\[|\]$/, "", v); n = split(v, a, ",")
      for (i = 1; i <= n; i++) { s = a[i]; gsub(/^[ \t"'\'']+|[ \t"'\'']+$/, "", s); if (s != "") print s }
    }' "$1"
}

# docs.<key> from .groma/config.yaml
cfg_docs() {
  v=""
  [ -f .groma/config.yaml ] && v=$(awk -v k="$1" '
    function ind(s) { match(s, /^ */); return RLENGTH }
    /^[ ]*#/ || /^[ ]*$/ { next }
    { i = ind($0); l = $0; sub(/^ */, "", l); sub(/[ ]+#.*/, "", l)
      if (ins && i == 0) ins = 0
      if (l ~ /^docs:/ && i == 0) { ins = 1; next }
      if (ins && index(l, k ":") == 1) { sub(/^[^:]*:[ ]*/, "", l); gsub(/["\047]/, "", l); print l; exit } }' .groma/config.yaml)
  echo "${v:-$2}"
}

# paths cleared by a justified Docs: task line
EXEMPT=""
# shellcheck disable=SC2016 # backticks are literal: the path may be written as `path`
[ -f "$CHANGE/tasks.md" ] && EXEMPT=$(sed -n 's/^[[:space:]]*- \[[ xX]\] Docs: `\{0,1\}\([^ `]*\)`\{0,1\} unchanged, because ..*/\1/p' "$CHANGE/tasks.md" | sed 's#^\./##')

impact=0 adr=0
if [ -d "$DOCS" ] && [ -n "$CHANGED" ]; then
  for doc in $(find "$DOCS" -type f -name '*.md' ! -path "$DOCS/_groma/*" ! -path "$DOCS/adr/*" | LC_ALL=C sort); do
    printf '%s\n' "$CHANGED" | grep -qxF "$doc" && continue
    printf '%s\n' "$EXEMPT" | grep -qxF "$doc" && continue
    hits=""
    for s in $(fm_sources "$doc"); do
      s=${s#./}; s=${s%/}
      case "$s" in "$DOCS" | "$DOCS"/*) continue ;; esac
      for p in $CHANGED; do
        case "$p" in "$s" | "$s"/*) hits="$hits$p$NL" ;; esac
      done
    done
    if [ -n "$hits" ]; then
      impact=$((impact + 1))
      printf 'impact%s%s%s%s\n' "$TAB" "$doc" "$TAB" "$(printf '%s' "$hits" | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')"
    fi
  done
fi

MODE=$(cfg_docs adr_from design-alternatives)
if [ "$MODE" != off ] && [ -f "$CHANGE/design.md" ]; then
  # decisions that need an ADR: id<TAB>title
  needs=$(awk -v mode="$MODE" '
    function flush() { if (id != "" && need) printf "%s\t%s\n", id, title; id = ""; need = 0 }
    /^##?#?[ \t]/ { flush() }
    /^###[ \t]+D[0-9]+([:. \t]|$)/ {
      l = $0; sub(/^###[ \t]+/, "", l); match(l, /^D[0-9]+/); id = substr(l, 1, RLENGTH); title = substr(l, RLENGTH + 1)
      sub(/^[:. \t]+/, "", title); sub(/[ \t]+$/, "", title); next
    }
    id != "" && mode == "design-alternatives" && /^Alternatives/ { need = 1 }
    id != "" && mode == "marked" && /^ADR:[ \t]*yes[ \t]*$/ { need = 1 }
    END { flush() }' "$CHANGE/design.md")
  origins=""
  # shellcheck disable=SC2044 # IFS is a newline and globbing is off
  [ -d "$DOCS/adr" ] && for a in $(find "$DOCS/adr" -type f -name "*.md"); do
    [ -f "$a" ] && origins="$origins $(fm_get "$a" origin)"
  done
  while IFS="$TAB" read -r id title; do
    [ -n "$id" ] || continue
    case " $origins " in *" $NAME#$id "*) continue ;; esac
    adr=$((adr + 1))
    printf 'adr%s%s#%s%s%s\n' "$TAB" "$NAME" "$id" "$TAB" "$title"
  done <<EOF
$needs
EOF
fi

printf 'summary%simpact=%d%sadr=%d\n' "$TAB" "$impact" "$TAB" "$adr"
[ "$GATE" -eq 1 ] && [ $((impact + adr)) -gt 0 ] && exit 4
exit 0
