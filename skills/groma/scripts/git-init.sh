#!/bin/sh
# Set up a git repository for a project: `git init` on main, `.gitignore` only when absent.
#
# Usage: git-init.sh [--check] [--type greenfield|brownfield] [--stack <list>] <project>
#   --check   write nothing; print the repository state and the recommended answer
#   --type    project type for the recommendation (default greenfield)
#   --stack   comma-separated stacks named in the interview (Node, Python, ...)
#
# .gitignore rows come from ../references/gitignore.md: stack `all`, the named
# stacks, and every row whose manifest exists at the project root.
#
# Output, tab-separated, one line:
#   --check: state<TAB>none<TAB>recommend=init|skip       (not inside a work tree)
#            state<TAB>parent<TAB><top level><TAB>recommend=use
#            state<TAB>repo<TAB><top level>                (the project is the top level)
#   init<TAB><project><TAB>branch=main<TAB>gitignore=written|kept
# Exit 0; 1 when the project is already the top level of a repository or git
# fails; usage errors exit 2.
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TABLE="$HERE/../references/gitignore.md"
usage() { echo "usage: git-init.sh [--check] [--type greenfield|brownfield] [--stack <list>] <project>" >&2; exit 2; }

CHECK=0 TYPE=greenfield STACK="" P=""
while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=1; shift ;;
    --type) [ $# -ge 2 ] || usage; TYPE=$2; shift 2 ;;
    --stack) [ $# -ge 2 ] || usage; STACK=$2; shift 2 ;;
    -*) usage ;;
    *) P=$1; shift ;;
  esac
done
case "$TYPE" in greenfield|brownfield) ;; *) usage ;; esac
[ -n "$P" ] && [ -d "$P" ] || usage
P=$(CDPATH='' cd -- "$P" && pwd -P)

top=$(git -C "$P" rev-parse --show-toplevel 2>/dev/null || true)
[ -z "$top" ] || top=$(CDPATH='' cd -- "$top" && pwd -P)

if [ "$CHECK" -eq 1 ]; then
  if [ -z "$top" ]; then
    rec=init
    [ "$TYPE" = greenfield ] || rec=skip
    printf 'state\tnone\trecommend=%s\n' "$rec"
  elif [ "$top" = "$P" ]; then
    printf 'state\trepo\t%s\n' "$top"
  else
    printf 'state\tparent\t%s\trecommend=use\n' "$top"
  fi
  exit 0
fi

[ "$top" != "$P" ] || { echo "already a git repository: $P" >&2; exit 1; }
[ -r "$TABLE" ] || { echo "missing: $TABLE" >&2; exit 1; }
# -b needs git 2.28; older git rejects the option before writing anything
if ! git -C "$P" init -q -b main 2>/dev/null; then
  git -C "$P" init -q
  git -C "$P" symbolic-ref HEAD refs/heads/main
fi

gi=kept
if [ ! -e "$P/.gitignore" ]; then
  set -f
  want=$(printf ',%s,' "$STACK" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
  # rows as stacks|manifests|patterns, comma lists without spaces or backticks
  awk -F '|' '/^\|/ && !/^\|[ ]*Stack[ ]*\|/ && !/^\|---/ {
      for (i = 2; i <= 4; i++) { gsub(/`/, "", $i); gsub(/^[ ]+|[ ]+$/, "", $i); gsub(/[ ]*,[ ]*/, ",", $i) }
      print $2 "|" $3 "|" $4 }' "$TABLE" |
  while IFS='|' read -r stacks manifests patterns; do
    pick=0
    IFS=,
    for s in $(printf '%s' "$stacks" | tr '[:upper:]' '[:lower:]'); do
      case "$s" in all) pick=1 ;; esac
      case "$want" in *",$s,"*) pick=1 ;; esac
    done
    for m in $manifests; do [ ! -e "$P/$m" ] || pick=1; done
    if [ "$pick" -eq 1 ]; then
      for x in $patterns; do printf '%s\n' "$x"; done
    fi
    unset IFS
  done | awk '!seen[$0]++' > "$P/.gitignore"
  gi=written
fi
printf 'init\t%s\tbranch=main\tgitignore=%s\n' "$P" "$gi"
