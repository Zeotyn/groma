#!/bin/sh
# Report tools groma relies on. Read-only, installs nothing.
#
# Usage: check-prereqs.sh
# Output, one line per tool, tab-separated:
#   <tool><TAB>ok|missing|too_old<TAB><version or -><TAB><needed for><TAB><install hint>
# Exit code 1 when a required tool is missing or too old, else 0.
set -eu

TAB=$(printf '\t')
fail=0

line() { printf '%s%s%s%s%s%s%s%s%s\n' "$1" "$TAB" "$2" "$TAB" "$3" "$TAB" "$4" "$TAB" "$5"; }

# major version number from a version string like v22.3.0 or 1.8.0
major() { echo "$1" | sed 's/^[^0-9]*//' | cut -d. -f1; }

check() { # name required(0/1) min_major version_cmd needed_for hint
  name=$1 required=$2 min=$3 cmd=$4 why=$5 hint=$6
  if ! command -v "$name" >/dev/null 2>&1; then
    line "$name" missing - "$why" "$hint"
    [ "$required" -eq 1 ] && fail=1
    return 0
  fi
  v=$(sh -c "$cmd" 2>/dev/null | head -n 1 | tr -d '\r') || v=""
  v=${v:-unknown}
  if [ "$min" -gt 0 ]; then
    mv=$(major "$v")
    case "$mv" in ''|*[!0-9]*) mv=0 ;; esac
    if [ "$mv" -lt "$min" ]; then
      line "$name" too_old "$v" "$why (needs >= $min)" "$hint"
      [ "$required" -eq 1 ] && fail=1
      return 0
    fi
  fi
  line "$name" ok "$v" "$why" "-"
}

check git 1 0 "git --version | awk '{print \$3}'" "history, freshness checks" "https://git-scm.com/downloads"
check node 1 22 "node --version" "npx skills, OpenSpec, GSD" "https://nodejs.org (v22 or newer)"
check npx 1 0 "npx --version" "npx skills, OpenSpec, GSD" "ships with Node.js"
check uv 0 0 "uv --version | awk '{print \$2}'" "graphify, Spec Kit (optional)" "https://docs.astral.sh/uv/"
check claude 0 0 "claude --version | awk '{print \$1}'" "agent: Claude Code (optional)" "https://code.claude.com"
check copilot 0 0 "copilot --version" "agent: GitHub Copilot CLI (optional)" "https://docs.github.com/copilot"
check gemini 0 0 "gemini --version" "agent: Gemini CLI (optional)" "https://geminicli.com"
check codex 0 0 "codex --version | awk '{print \$NF}'" "agent: Codex (optional)" "https://developers.openai.com/codex"

exit "$fail"
