#!/bin/sh
# groma fallback installer: links (or copies) the groma skills into the user
# skill folders of every detected agent.
#
#   curl -fsSL https://raw.githubusercontent.com/Zeotyn/groma/main/install.sh | sh
#   sh install.sh [options]
#
# Options:
#   --ref <tag>        install a released version (clones into ~/.groma/repo)
#   --source <dir>     use a local checkout (default: this script's folder if it holds skills/)
#   --agents <list>    comma-separated: claude,copilot,gemini,cursor,codex (default: detected)
#   --copy             copy instead of symlink (Windows, or to freeze a version)
#   --dry-run          print what would happen, change nothing
#   --uninstall        remove what this installer created, nothing else
#   --home <dir>       target home folder (default: $HOME), mainly for tests
#
# Never overwrites a skill folder it did not create. Re-running is safe.
set -eu

REPO_URL=${GROMA_REPO_URL:-https://github.com/Zeotyn/groma.git}
HOME_DIR=${HOME}
REF=""
SOURCE=""
AGENTS=""
COPY=0
DRY=0
UNINSTALL=0
MARKER=".groma-installed"

while [ $# -gt 0 ]; do
  case "$1" in
    --ref) REF=$2; shift 2 ;;
    --source) SOURCE=$2; shift 2 ;;
    --agents) AGENTS=$(echo "$2" | tr ',' ' '); shift 2 ;;
    --copy) COPY=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --home) HOME_DIR=$2; shift 2 ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

say() { printf '%s\n' "$*"; }
run() { if [ "$DRY" -eq 1 ]; then say "dry-run: $*"; else "$@"; fi; }

# --- source ------------------------------------------------------------------
if [ -z "$SOURCE" ] && [ -z "$REF" ]; then
  here=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || echo "")
  if [ -n "$here" ] && [ -d "$here/skills/groma" ]; then SOURCE=$here; fi
fi
if [ -z "$SOURCE" ]; then
  SOURCE="$HOME_DIR/.groma/repo"
  command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 3; }
  if [ "$UNINSTALL" -eq 0 ]; then
    if [ -d "$SOURCE/.git" ]; then
      run git -C "$SOURCE" fetch -q --tags origin
      if [ -n "$REF" ]; then run git -C "$SOURCE" checkout -q "$REF"; else run git -C "$SOURCE" pull -q --ff-only; fi
    else
      run mkdir -p "$(dirname "$SOURCE")"
      if [ -n "$REF" ]; then run git clone -q --depth 1 --branch "$REF" "$REPO_URL" "$SOURCE"
      else run git clone -q --depth 1 "$REPO_URL" "$SOURCE"; fi
    fi
  fi
fi
SOURCE=$(CDPATH='' cd -- "$SOURCE" 2>/dev/null && pwd || echo "$SOURCE")

# --- agents ------------------------------------------------------------------
skills_dir() {
  case "$1" in
    claude) echo "$HOME_DIR/.claude/skills" ;;
    copilot) echo "$HOME_DIR/.copilot/skills" ;;
    gemini) echo "$HOME_DIR/.gemini/skills" ;;
    cursor) echo "$HOME_DIR/.cursor/skills" ;;
    codex) echo "$HOME_DIR/.agents/skills" ;;
    *) return 1 ;;
  esac
}
agent_home() {
  case "$1" in
    claude) echo "$HOME_DIR/.claude" ;;
    copilot) echo "$HOME_DIR/.copilot" ;;
    gemini) echo "$HOME_DIR/.gemini" ;;
    cursor) echo "$HOME_DIR/.cursor" ;;
    codex) echo "$HOME_DIR/.codex" ;;
  esac
}
if [ -z "$AGENTS" ]; then
  for a in claude copilot gemini cursor codex; do
    [ -d "$(agent_home "$a")" ] && AGENTS="$AGENTS $a"
  done
fi
for a in $AGENTS; do skills_dir "$a" >/dev/null || { echo "unknown agent: $a" >&2; exit 2; }; done
if [ -z "$(echo "$AGENTS" | tr -d ' ')" ]; then
  say "No agent folders found in $HOME_DIR (.claude, .copilot, .gemini, .cursor, .codex). Use --agents."
  exit 1
fi

# --- install / uninstall -------------------------------------------------------
ours() { # target -> 0 if created by this installer from SOURCE
  t=$1 name=$2
  if [ -L "$t" ]; then
    [ "$(readlink "$t")" = "$SOURCE/skills/$name" ] && return 0
    return 1
  fi
  [ -f "$t/$MARKER" ] && return 0
  return 1
}

linked=0 copied=0 already=0 conflicts=0 removed=0
for a in $AGENTS; do
  dir=$(skills_dir "$a")
  [ "$UNINSTALL" -eq 1 ] || run mkdir -p "$dir"
  for src in "$SOURCE"/skills/*/; do
    [ -d "$src" ] || continue
    src=${src%/}; name=${src##*/}
    t="$dir/$name"
    if [ "$UNINSTALL" -eq 1 ]; then
      if [ -e "$t" ] || [ -L "$t" ]; then
        if ours "$t" "$name"; then run rm -rf "$t"; removed=$((removed + 1)); say "removed  $a: $name"
        else say "kept     $a: $name (not installed by groma)"; fi
      fi
      continue
    fi
    if [ -e "$t" ] || [ -L "$t" ]; then
      if ours "$t" "$name"; then
        if [ "$COPY" -eq 1 ] && [ ! -L "$t" ]; then
          run rm -rf "$t"; run cp -R "$src" "$t"
          [ "$DRY" -eq 1 ] || printf 'source=%s\n' "$SOURCE" > "$t/$MARKER"
          copied=$((copied + 1)); say "updated  $a: $name (copy)"
        else
          already=$((already + 1)); say "already  $a: $name"
        fi
      else
        conflicts=$((conflicts + 1)); say "CONFLICT $a: $t exists and was not installed by groma, skipped"
      fi
      continue
    fi
    if [ "$COPY" -eq 1 ]; then
      run cp -R "$src" "$t"
      [ "$DRY" -eq 1 ] || printf 'source=%s\n' "$SOURCE" > "$t/$MARKER"
      copied=$((copied + 1)); say "copied   $a: $name"
    else
      run ln -s "$SOURCE/skills/$name" "$t"
      linked=$((linked + 1)); say "linked   $a: $name"
    fi
  done
done

if [ "$UNINSTALL" -eq 1 ]; then
  say "groma: removed $removed"
else
  say "groma: linked $linked, copied $copied, already installed $already, conflicts $conflicts"
fi
[ "$conflicts" -eq 0 ]
