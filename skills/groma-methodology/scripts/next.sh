#!/bin/sh
# The one next action for a project. Local files and git state only, no network.
#
# Usage: next.sh [--short|--long|--json] [project]
#   project defaults to the current directory
#
# Prints at most one action, the first rung of this ladder that applies:
#   rung  when                                             short         long
#   1     rebase or merge in progress                      rebase        Rebase in progress: git rebase --continue or git rebase --abort
#   2     change done, docs impact or ADR open             docs c007     <change>: all tasks done, <what status.sh asks for>
#   3     change done                                      verify c007   <change>: all tasks done, verify: /opsx:verify <change>
#   4     uncommitted files                                commit 4      4 files uncommitted: git add and git commit, or git stash
#   5     milestone at its gate                            gate m003     <milestone>: milestone gate: <first open task>
#   6     main branch commits not pushed                   push 3        Push 3 commits on main: git push
#         (not when git.push is never)
#   7     ADR still proposed, origin change archived       adr 0015      ADR 0015 still proposed (<change> archived): accept or reject
#   8     open change with the newest commit               apply c007    <change>: 3/9 tasks, continue: /opsx:apply <change>
#         (milestones excluded)
# Rungs 2 to 7 are lines of status.sh, so its toggles in .groma/config.yaml
# apply here too. The /opsx: commands appear only for openspec/changes.
#
# Output: --long (default) one sentence, --short at most 20 characters,
#   --json {"rung":N,"short":"...","long":"..."}. Nothing applies: no output.
# Exit codes: 0 also when nothing is printed, 2 usage error.
#
# Cache: when <project>/.groma/ exists and the project has a commit, the result
# is kept in .groma/.cache/next, keyed on HEAD, `git status --porcelain` and the
# local and remote branch heads, and dropped when a file in the changes folder
# is newer; .groma/config.yaml is part of the key too. .groma/.cache/.gitignore ("*") keeps the folder out of git.
# Rung 1 is checked on every run. Nothing else in the project is written.
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=SCRIPTDIR/lib-changes.sh
. "$HERE/lib-changes.sh"

FORMAT=long
ROOT=.
while [ $# -gt 0 ]; do
  case "$1" in
    --short|--long|--json) FORMAT=${1#--}; shift ;;
    -*) echo "unknown argument: $1" >&2; exit 2 ;;
    *) ROOT=$1; shift ;;
  esac
done

emit() { # rung short long
  [ -n "$1" ] || return 0
  case "$FORMAT" in
    short) printf '%s\n' "$2" ;;
    long) printf '%s\n' "$3" ;;
    json) printf '{"rung":%s,"short":"%s","long":"%s"}\n' "$1" "$(json_escape "$2")" "$(json_escape "$3")" ;;
  esac
}

# git dir and HEAD in one call; HEAD stays empty outside git and before the first commit
GIT_DIR_ABS=""
HEAD_SHA=""
{ IFS= read -r GIT_DIR_ABS; IFS= read -r HEAD_SHA; } <<EOF || true
$(git -C "$ROOT" rev-parse --absolute-git-dir --verify -q HEAD 2>/dev/null || true)
EOF

if [ -n "$GIT_DIR_ABS" ]; then
  if [ -d "$GIT_DIR_ABS/rebase-merge" ] || [ -d "$GIT_DIR_ABS/rebase-apply" ]; then
    emit 1 rebase "Rebase in progress: git rebase --continue or git rebase --abort"
    exit 0
  fi
  if [ -f "$GIT_DIR_ABS/MERGE_HEAD" ]; then
    emit 1 merge "Merge in progress: git merge --continue or git merge --abort"
    exit 0
  fi
fi

DIR=$(changes_dir "$ROOT")

CACHE=""
key=""
if [ -n "$HEAD_SHA" ] && [ -d "$ROOT/.groma" ] && mkdir -p "$ROOT/.groma/.cache" 2>/dev/null; then
  [ -e "$ROOT/.groma/.cache/.gitignore" ] || echo '*' > "$ROOT/.groma/.cache/.gitignore" 2>/dev/null || true
  CACHE="$ROOT/.groma/.cache/next"
  key=$({ echo "$HEAD_SHA"
    git -C "$ROOT" --no-optional-locks status --porcelain 2>/dev/null
    git -C "$ROOT" for-each-ref --format='%(objectname) %(refname)' refs/heads refs/remotes 2>/dev/null
    cat "$ROOT/.groma/config.yaml" 2>/dev/null
  } | git hash-object --stdin)
  if [ -f "$CACHE" ]; then
    ckey="" rung="" short="" long=""
    { IFS= read -r ckey; IFS= read -r rung; IFS= read -r short; IFS= read -r long; } < "$CACHE" || true
    if [ "$ckey" = "$key" ] && { [ -z "$DIR" ] || [ -z "$(find "$DIR" -newer "$CACHE" 2>/dev/null | head -n 1)" ]; }; then
      emit "$rung" "$short" "$long"
      exit 0
    fi
  fi
fi

opsx=0
case "$DIR" in */openspec/changes) opsx=1 ;; esac
TAB=$(printf '\t')

# rungs 2 to 7: the status.sh line with the lowest rung
rung="" short="" long=""
IFS="$TAB" read -r rung short long <<EOF || true
$(sh "$HERE/status.sh" --root "$ROOT" 2>/dev/null | awk -v push="$(cfg_value push ask git)" -v opsx="$opsx" '
  function id(n) { sub(/-.*/, "", n); return n }
  function after(s, mark) { return substr(s, index(s, mark) + length(mark)) }
  { r = 0 }
  / tasks → (update .* or add a Docs: task line|write a proposed ADR for .*)$/ {
    r = 2; s = "docs " id($1); l = $1 ": all tasks done, " after($0, " tasks → ") }
  / tasks → verify, then archive$/ {
    r = 3; s = "verify " id($1); l = $1 ": all tasks done, verify" (opsx ? ": /opsx:verify " $1 : ", then archive") }
  /^working tree: [0-9]+ files uncommitted / {
    r = 4; s = "commit " $3; l = $3 " files uncommitted: git add and git commit, or git stash" }
  / tasks → gate: / {
    r = 5; s = "gate " id($1); l = $1 ": milestone gate: " after($0, " tasks → gate: ") }
  /^[^ ]+: [0-9]+ commits not pushed / && push != "never" {
    r = 6; s = "push " $2; l = "Push " $2 " commits on " substr($1, 1, length($1) - 1) ": git push" }
  /^ADR [0-9]+ still proposed \(.* archived\) / {
    r = 7; s = "adr " $2; l = substr($0, 1, index($0, " → ") - 1) ": accept or reject" }
  r && (!best || r < best) { best = r; bs = s; bl = l }
  END { if (best) printf "%s\t%s\t%s\n", best, bs, bl }' || true)
EOF

# rung 8: the open change whose folder has the newest commit
if [ -z "$rung" ]; then
  best_t=-1
  while IFS="$TAB" read -r name loc path <&3; do
    [ "$loc" = active ] || continue
    case "$name" in m[0-9]*-*) continue ;; esac
    tf="$path/tasks.md"
    [ -f "$tf" ] || continue
    total=$(grep -c '^[[:space:]]*- \[[ xX]\]' "$tf" || true)
    done_n=$(grep -c '^[[:space:]]*- \[[xX]\]' "$tf" || true)
    [ "$done_n" -lt "$total" ] || continue
    t=0
    [ -z "$HEAD_SHA" ] || t=$(git -C "$ROOT" log -1 --format=%ct -- "${path#"$ROOT"/}" 2>/dev/null || true)
    if [ "${t:-0}" -gt "$best_t" ]; then
      best_t=${t:-0}
      rung=8; short="apply ${name%%-*}"; long="$name: $done_n/$total tasks"
      [ "$opsx" -eq 0 ] || long="$long, continue: /opsx:apply $name"
    fi
  done 3<<EOF
$(list_changes "$DIR")
EOF
fi

short=$(printf '%s' "$short" | cut -c1-20)
if [ -n "$CACHE" ]; then
  if printf '%s\n%s\n%s\n%s\n' "$key" "$rung" "$short" "$long" > "$CACHE.$$" 2>/dev/null; then
    mv "$CACHE.$$" "$CACHE" 2>/dev/null || rm -f "$CACHE.$$"
  fi
fi
emit "$rung" "$short" "$long"
