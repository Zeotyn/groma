#!/bin/sh
# Never-overwrite invariant (test level 3).
#
#   checksum.sh snapshot <dir> <manifest>   record SHA-256 of every file in <dir>
#   checksum.sh verify   <dir> <manifest>   fail if a recorded file changed or vanished
#
# New files are allowed. The .git directory is ignored.
# File names containing newlines are not supported.
set -eu

usage() { echo "usage: $0 snapshot|verify <dir> <manifest>" >&2; exit 2; }
[ $# -eq 3 ] || usage
mode=$1 dir=$2 manifest=$3
[ -d "$dir" ] || { echo "not a directory: $dir" >&2; exit 2; }

if command -v sha256sum >/dev/null 2>&1; then
  hash_file() { sha256sum "$1" | cut -d' ' -f1; }
else
  hash_file() { shasum -a 256 "$1" | cut -d' ' -f1; }
fi

case "$mode" in
  snapshot)
    : > "$manifest"
    (cd "$dir" && find . -type f ! -path './.git/*' | LC_ALL=C sort) |
      while IFS= read -r f; do
        printf '%s  %s\n' "$(hash_file "$dir/$f")" "$f" >> "$manifest"
      done
    echo "snapshot: $(wc -l < "$manifest" | tr -d ' ') files"
    ;;
  verify)
    [ -f "$manifest" ] || { echo "manifest not found: $manifest" >&2; exit 2; }
    bad=0
    while IFS= read -r line; do
      expected=${line%%  *}
      f=${line#*  }
      if [ ! -f "$dir/$f" ]; then
        echo "MISSING  $f"
        bad=$((bad + 1))
      elif [ "$(hash_file "$dir/$f")" != "$expected" ]; then
        echo "CHANGED  $f"
        bad=$((bad + 1))
      fi
    done < "$manifest"
    if [ "$bad" -gt 0 ]; then
      echo "invariant violated: $bad pre-existing file(s) changed or removed"
      exit 1
    fi
    echo "invariant ok: all pre-existing files unchanged"
    ;;
  *) usage ;;
esac
