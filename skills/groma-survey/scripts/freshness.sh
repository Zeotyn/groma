#!/bin/sh
# Report stale documentation. Read-only.
#
# Usage: freshness.sh [dir] [--docs <docs-dir>] [--today YYYY-MM-DD] [--adr-days <n>]
#
# A doc is stale when
#   (a) frontmatter last_reviewed + review_after_days lies before today, or
#   (b) the newest commit touching any path in frontmatter `sources` is newer
#       than the newest commit touching the doc, or
#   (c) without `sources`: the newest commit touching any non-Markdown file
#       outside the docs dir is newer than the doc.
# With last_reviewed set, (b) and (c) also need that commit's UTC day to lie
# after last_reviewed: a review covers source commits up to the end of its day.
# Sources inside the docs dir are ignored; if none remain, only (a) applies.
# ADRs (<docs>/adr/*) skip (b) and (c): an ADR with `status: proposed` whose
# `date` (else last commit) is more than --adr-days (default 30) old is stale.
# A doc is broken when a source does not exist or lies under a change folder
# (CHANGE_DIRS below), which moves on archive; its archive/ folder is stable.
#
# Output, one line per doc, tab-separated (priority broken > stale > fresh):
#   broken<TAB><doc><TAB><broken paths>[; <stale reason>]
#   stale<TAB><doc><TAB><reason>
#   fresh<TAB><doc>
#   unknown<TAB><doc><TAB><reason>
# followed by: summary<TAB>stale=<n><TAB>fresh=<n><TAB>unknown=<n><TAB>broken=<n>
# Exit code 0 even when stale docs exist (it is a report, not a gate).
set -eu

DIR=.
DOCS=docs
TODAY=$(date -u +%Y-%m-%d)
ADR_DAYS=30
CHANGE_DIRS=openspec/changes/
while [ $# -gt 0 ]; do
  case "$1" in
    --docs) DOCS=$2; shift 2 ;;
    --today) TODAY=$2; shift 2 ;;
    --adr-days) ADR_DAYS=$2; shift 2 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) DIR=$1; shift ;;
  esac
done
[ -d "$DIR" ] || { echo "not a directory: $DIR" >&2; exit 2; }
case "$ADR_DAYS" in '' | *[!0-9]*) echo "--adr-days needs a number: $ADR_DAYS" >&2; exit 2 ;; esac
DOCS=${DOCS#./}; DOCS=${DOCS%/}; DOCS=${DOCS:-.}
cd "$DIR"

TAB=$(printf '\t')
in_git=0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git rev-parse HEAD >/dev/null 2>&1 && in_git=1

# days since 1970-01-01 for YYYY-MM-DD (proleptic Gregorian), portable awk
days() {
  echo "$1" | awk -F- '{
    y = $1 + 0; m = $2 + 0; d = $3 + 0
    if (m <= 2) { y -= 1; m += 12 }
    era = int(y / 400); yoe = y - era * 400
    doy = int((153 * (m - 3) + 2) / 5) + d - 1
    doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
    print era * 146097 + doe - 719468
  }'
}

last_commit() { # epoch of newest commit touching paths, 0 if none
  if [ "$in_git" -eq 1 ]; then
    t=$(git log -1 --format=%ct -- "$@" 2>/dev/null || true)
    echo "${t:-0}"
  else
    echo 0
  fi
}

ymd() { # epoch -> YYYY-MM-DD
  awk -v t="$1" 'BEGIN {
    z = int(t / 86400) + 719468; era = int(z / 146097); doe = z - era * 146097
    yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365)
    y = yoe + era * 400; doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100))
    mp = int((5 * doy + 2) / 153); d = doy - int((153 * mp + 2) / 5) + 1
    m = mp < 10 ? mp + 3 : mp - 9; if (m <= 2) y++
    printf "%04d-%02d-%02d\n", y, m, d
  }'
}

# true when commit epoch $1 is newer than the doc and, if set, on a day after last_reviewed
code_newer() {
  [ "$1" -gt "$doc_t" ] && { [ -z "$lr_day" ] || [ $(($1 / 86400)) -gt "$lr_day" ]; }
}

# frontmatter value for key (scalar), empty if absent
fm_get() {
  awk -v k="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 {
      if (index($0, k ":") == 1) {
        v = substr($0, length(k) + 2); gsub(/^[ \t"'\'']+|[ \t"'\'']+$/, "", v); print v; exit
      }
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

stale=0 fresh=0 unknown=0 broken=0
today_days=$(days "$TODAY")
code_epoch=""

if [ ! -d "$DOCS" ]; then
  printf 'summary%sstale=0%sfresh=0%sunknown=0%sbroken=0\n' "$TAB" "$TAB" "$TAB" "$TAB"
  exit 0
fi

find "$DOCS" -type f -name '*.md' ! -path "$DOCS/_groma/*" | LC_ALL=C sort > "${TMPDIR:-/tmp}/groma-fresh.$$"
trap 'rm -f "${TMPDIR:-/tmp}/groma-fresh.$$"' EXIT

while IFS= read -r doc; do
  reasons=""
  lr=$(fm_get "$doc" last_reviewed)
  rad=$(fm_get "$doc" review_after_days)
  if [ -n "$lr" ] && [ -n "$rad" ]; then
    age=$((today_days - $(days "$lr")))
    if [ "$age" -gt "$rad" ]; then
      reasons="review overdue: last_reviewed $lr is $age days old (limit $rad)"
    fi
  fi

  doc_t=$(last_commit "$doc")
  lr_day="" lr_note=""
  case "$lr" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) lr_day=$(days "$lr") lr_note=", last_reviewed $lr" ;; esac
  bad="" has_src=0 srcs=""
  case "$doc" in "$DOCS"/adr/*) is_adr=1 ;; *) is_adr=0 ;; esac
  if [ "$is_adr" -eq 0 ]; then
    for s in $(fm_sources "$doc"); do
      has_src=1 s=${s#./}
      case "$s" in "$DOCS" | "$DOCS"/*) continue ;; esac
      if [ ! -e "$s" ]; then
        bad=${bad:+"$bad; "}"source missing: $s"
      else
        case "$s" in
          "$CHANGE_DIRS"archive | "$CHANGE_DIRS"archive/*) srcs="$srcs $s" ;;
          "$CHANGE_DIRS"?*) bad=${bad:+"$bad; "}"source in change folder: $s" ;;
          *) srcs="$srcs $s" ;;
        esac
      fi
    done
  fi

  if [ "$is_adr" -eq 1 ]; then
    if [ "$(fm_get "$doc" status)" = proposed ]; then
      since=$(fm_get "$doc" date)
      case "$since" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) since="" ;; esac
      [ -z "$since" ] && [ "$doc_t" -gt 0 ] && since=$(ymd "$doc_t")
      if [ -n "$since" ] && [ $((today_days - $(days "$since"))) -gt "$ADR_DAYS" ]; then
        reasons=${reasons:+"$reasons; "}"proposed since $since, accept or reject"
      fi
    fi
  elif [ "$in_git" -eq 1 ] && [ "$doc_t" -eq 0 ]; then
    if [ -z "$reasons" ] && [ -z "$bad" ]; then
      unknown=$((unknown + 1))
      printf 'unknown%s%s%snot committed yet\n' "$TAB" "$doc" "$TAB"
      continue
    fi
  elif [ "$in_git" -eq 1 ]; then
    if [ -n "$srcs" ]; then
      newest=0 newest_src=""
      for s in $srcs; do
        t=$(last_commit "$s")
        if [ "$t" -gt "$newest" ]; then newest=$t newest_src=$s; fi
      done
      if code_newer "$newest"; then
        r="code changed: $newest_src on $(ymd "$newest"), doc last changed $(ymd "$doc_t")$lr_note"
        reasons=${reasons:+"$reasons; "}$r
      fi
    elif [ "$has_src" -eq 0 ]; then
      if [ -z "$code_epoch" ]; then
        code_epoch=$(last_commit . ":(exclude)$DOCS" ":(exclude)*.md")
      fi
      if code_newer "$code_epoch"; then
        r="repository code changed on $(ymd "$code_epoch"), doc last changed $(ymd "$doc_t") (no sources in frontmatter)$lr_note"
        reasons=${reasons:+"$reasons; "}$r
      fi
    fi
  fi

  if [ -n "$bad" ]; then
    broken=$((broken + 1))
    printf 'broken%s%s%s%s\n' "$TAB" "$doc" "$TAB" "$bad${reasons:+; $reasons}"
  elif [ -n "$reasons" ]; then
    stale=$((stale + 1))
    printf 'stale%s%s%s%s\n' "$TAB" "$doc" "$TAB" "$reasons"
  else
    fresh=$((fresh + 1))
    printf 'fresh%s%s\n' "$TAB" "$doc"
  fi
done < "${TMPDIR:-/tmp}/groma-fresh.$$"

printf 'summary%sstale=%d%sfresh=%d%sunknown=%d%sbroken=%d\n' "$TAB" "$stale" "$TAB" "$fresh" "$TAB" "$unknown" "$TAB" "$broken"
