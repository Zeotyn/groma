#!/bin/sh
# Check that a release tag matches every version in the repository, and print
# the tag's CHANGELOG section for the GitHub release notes.
#
# Usage: scripts/release-check.sh [--root <dir>] [--notes] v<major>.<minor>.<patch>
#   --root   repository to check (default: this script's repository)
#   --notes  print the body of `## [<version>]` from CHANGELOG.md, then exit
#
# Checked: the tag looks like v<semver>; the plugin manifests, every plugin
# entry (bundle) of the marketplace, package.json and skills/groma/VERSION all
# declare that version;
# CHANGELOG.md has a `## [<version>]` section. One line per problem.
# Exit codes: 0 ok, 1 a check failed, 2 usage error.
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
NOTES=0
TAG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "usage: release-check.sh [--root <dir>] [--notes] <tag>" >&2; exit 2; }
            ROOT=$2; shift 2 ;;
    --notes) NOTES=1; shift ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) TAG=$1; shift ;;
  esac
done
[ -n "$TAG" ] || { echo "usage: release-check.sh [--root <dir>] [--notes] <tag>" >&2; exit 2; }

if ! printf '%s\n' "$TAG" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'; then
  echo "tag must look like v<major>.<minor>.<patch>, got: $TAG"
  exit 1
fi
VERSION=${TAG#v}
CHANGELOG="$ROOT/CHANGELOG.md"

# body of the version's section: the lines after `## [<version>]` up to the next `## [`
section() {
  [ -f "$CHANGELOG" ] || return 0
  awk -v v="$VERSION" '
    index($0, "## [" v "]") == 1 { on = 1; next }
    on && /^## \[/ { exit }
    on { print }' "$CHANGELOG" | sed -e '/./,$!d'
}

if [ "$NOTES" -eq 1 ]; then
  section
  exit 0
fi

failed=0
fail() { echo "$1"; failed=1; }

# first "version": "<v>" value in a JSON file
json_version() {
  sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -n 1
}

# every plugin entry of a marketplace: `version<TAB><entry name><TAB><v>` per
# "version" (named after the last "name" before it), then `missing<TAB><n>` when
# fewer versions than "source" keys exist
marketplace_versions() {
  awk '{ s = s $0 " " }
    END {
      re = "\"(name|source|version)\"[[:space:]]*:[[:space:]]*\"[^\"]*\""
      while (match(s, re)) {
        t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
        k = t; sub(/^"/, "", k); sub(/".*/, "", k)
        v = t; sub(/^"[^"]*"[[:space:]]*:[[:space:]]*"/, "", v); sub(/"$/, "", v)
        if (k == "name") n = v
        else if (k == "source") src++
        else { ver++; printf "version\t%s\t%s\n", n, v }
      }
      if (src > ver) printf "missing\t%d\n", src - ver
    }' "$1"
}

mp=.claude-plugin/marketplace.json
if [ -f "$ROOT/$mp" ]; then
  tab=$(printf '\t')
  found=0
  while IFS=$tab read -r kind name v; do
    case "$kind" in
      version)
        found=1
        [ "$v" = "$VERSION" ] || fail "$mp declares $v for $name, tag is $VERSION" ;;
      missing)
        if [ "$name" -eq 1 ]; then
          fail "$mp: 1 plugin entry declares no version"
        else
          fail "$mp: $name plugin entries declare no version"
        fi ;;
    esac
  done <<EOF
$(marketplace_versions "$ROOT/$mp")
EOF
  [ "$found" -eq 1 ] || fail "$mp declares no version"
fi

for m in .claude-plugin/plugin.json .codex-plugin/plugin.json .cursor-plugin/plugin.json \
         gemini-extension.json package.json; do
  [ -f "$ROOT/$m" ] || continue
  v=$(json_version "$ROOT/$m")
  if [ -z "$v" ]; then
    fail "$m declares no version"
  elif [ "$v" != "$VERSION" ]; then
    fail "$m declares $v, tag is $VERSION"
  fi
done

if [ -f "$ROOT/skills/groma/VERSION" ]; then
  v=$(tr -d '[:space:]' < "$ROOT/skills/groma/VERSION")
  [ "$v" = "$VERSION" ] || fail "skills/groma/VERSION declares $v, tag is $VERSION"
fi

if [ ! -f "$CHANGELOG" ] || ! grep -Fq "## [$VERSION]" "$CHANGELOG"; then
  fail "CHANGELOG.md has no section ## [$VERSION]; rename [Unreleased] for the release"
fi

[ "$failed" -eq 0 ] || exit 1
echo "release $TAG: ok"
