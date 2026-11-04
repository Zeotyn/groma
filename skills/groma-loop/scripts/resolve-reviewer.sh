#!/bin/sh
# Pick the reviewer for a loop phase.
#
# Usage: resolve-reviewer.sh <author-agent> [--phase propose|apply]
#                            [--config .groma/config.yaml] [--author-model <m>]
#
# Reads review.<phase>.reviewer from the config (default: auto).
#   auto    1. another vendor's CLI that answers a probe (codex, gemini, copilot, claude)
#           2. the author's agent with a different model (claude: opus <-> sonnet)
#           3. self-review in a fresh context
#   pinned  <agent>[:<model>] or self; on probe failure fall back along the auto order
#
# Output: reviewer=<r>, kind=pinned|other-vendor|other-model|self-review, reason=<text>
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
AUTHOR=""
PHASE=apply
CFG=.groma/config.yaml
AUTHOR_MODEL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --phase) PHASE=$2; shift 2 ;;
    --config) CFG=$2; shift 2 ;;
    --author-model) AUTHOR_MODEL=$2; shift 2 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) AUTHOR=$1; shift ;;
  esac
done
[ -n "$AUTHOR" ] || { echo "usage: $0 <author-agent> [--phase p] [--config f] [--author-model m]" >&2; exit 2; }

pinned=auto
if [ -f "$CFG" ]; then
  pinned=$(awk -v phase="$PHASE" '
    function ind(s) { match(s, /^ */); return RLENGTH }
    /^[ ]*#/ || /^[ ]*$/ { next }
    {
      i = ind($0); l = $0; sub(/^ */, "", l); sub(/[ ]+#.*/, "", l)
      if (inp && i <= pi) inp = 0
      if (inr && i <= ri) inr = 0
      if (l ~ /^review:/) { inr = 1; ri = i; next }
      if (inr && l ~ ("^" phase ":")) { inp = 1; pi = i; next }
      if (inp && l ~ /^reviewer:/) { sub(/^reviewer:[ ]*/, "", l); gsub(/["\047]/, "", l); print l; exit }
    }' "$CFG")
  pinned=${pinned:-auto}
fi

notes=""
note() { notes=${notes:+"$notes; "}$1; }
probe() { sh "$HERE/review.sh" --probe "$1" >/dev/null 2>&1; }
emit() { printf 'reviewer=%s\nkind=%s\nreason=%s\n' "$1" "$2" "$3"; exit 0; }

if [ "$pinned" != auto ]; then
  [ "$pinned" = self ] && emit self self-review "pinned in config"
  if probe "$pinned"; then emit "$pinned" pinned "pinned in config"; fi
  note "pinned $pinned: probe failed"
fi

for cand in codex gemini copilot claude; do
  [ "$cand" = "$AUTHOR" ] && continue
  if ! command -v "$cand" >/dev/null 2>&1; then continue; fi
  if probe "$cand"; then
    note "other vendor $cand answers"
    emit "$cand" other-vendor "$notes"
  fi
  note "$cand: probe failed"
done

if [ "$AUTHOR" = claude ]; then
  case "$AUTHOR_MODEL" in
    sonnet*|*sonnet*) other=opus ;;
    *) other=sonnet ;;
  esac
  if probe "claude:$other"; then
    note "no other vendor available, using another Claude model"
    emit "claude:$other" other-model "$notes"
  fi
  note "claude:$other: probe failed"
fi

note "no independent reviewer available"
emit self self-review "$notes"
