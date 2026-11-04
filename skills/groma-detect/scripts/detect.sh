#!/bin/sh
# Classify a folder as greenfield or brownfield.
#
# Usage: detect.sh [dir]
# Output (key=value lines, stable order):
#   project_type=greenfield|brownfield
#   source_files=<n>  manifests=<n>  docs_files=<n>  commits=<n>
#   signal=<human-readable reason>   (zero or more)
#
# Rules and patterns come from ../references/signals.md. Read-only.
set -eu

HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TABLE="$HERE/../references/signals.md"
DIR=${1:-.}
[ -d "$DIR" ] || { echo "not a directory: $DIR" >&2; exit 2; }
[ -f "$TABLE" ] || { echo "signal table not found: $TABLE" >&2; exit 2; }

commits=0
if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commits=$(git -C "$DIR" rev-list --count HEAD 2>/dev/null || echo 0)
fi

(cd "$DIR" && find . -type f) | awk -v commits="$commits" '
  # pass 1: the signal table
  FNR == NR {
    if ($0 !~ /^\|/) next
    n = split($0, c, "|")
    if (n < 4) next
    kind = c[2]; pat = c[3]; label = c[4]
    gsub(/^[ \t]+|[ \t]+$/, "", kind); gsub(/^[ \t]+|[ \t]+$/, "", pat); gsub(/^[ \t]+|[ \t]+$/, "", label)
    if (kind == "source") src[pat] = label
    else if (kind == "nonsource") non[pat] = label
    else if (kind == "manifest") man[pat] = label
    else if (kind == "ignore") ign[pat] = 1
    next
  }
  # pass 2: file list
  {
    np = split($0, parts, "/")
    skip = 0
    for (i = 2; i < np; i++) if (parts[i] in ign) { skip = 1; break }
    if (skip) next
    base = parts[np]
    if (base in man) { manifests++; mlabel[base] = man[base]; next }
    dot = 0
    for (i = length(base); i > 1; i--) if (substr(base, i, 1) == ".") { dot = i; break }
    if (dot == 0) next
    ext = tolower(substr(base, dot))
    if (ext in src) { sources++; scount[ext]++ }
    else if (ext in non) {
      if (ext == ".md" || ext == ".mdx" || ext == ".rst" || ext == ".adoc") docs++
    }
    else { sources++; ucount[ext]++ }
  }
  END {
    brown = (sources > 0 || manifests > 0 || commits > 10)
    print "project_type=" (brown ? "brownfield" : "greenfield")
    print "source_files=" (sources + 0)
    print "manifests=" (manifests + 0)
    print "docs_files=" (docs + 0)
    print "commits=" (commits + 0)
    for (e in scount) printf "signal=source files: %s (%s) x%d\n", e, src[e], scount[e] | "sort"
    for (e in ucount) printf "signal=source files: %s (unrecognized stack) x%d\n", e, ucount[e] | "sort"
    for (m in mlabel) printf "signal=manifest: %s (%s)\n", m, mlabel[m] | "sort"
    close("sort")
    if (commits > 10) printf "signal=git history: %d commits\n", commits
    if (!brown && sources == 0) print "signal=no source files"
    if (docs > 0) print "signal=docs present"
  }
' "$TABLE" -
