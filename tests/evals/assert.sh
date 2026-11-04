#!/bin/sh
# Assertions for one eval run.
# Usage: assert.sh <fixture> <project-dir> <checksum-manifest>
set -u

FX=$1 P=$2 M=$3
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
fails=0

ok() { echo "   ok    $1"; }
no() { echo "   FAIL  $1"; fails=$((fails + 1)); }
check() { # description command...
  d=$1; shift
  if "$@" >/dev/null 2>&1; then ok "$d"; else no "$d"; fi
}
has() { grep -Eqi -- "$2" "$1" 2>/dev/null; }
any_has() { # pattern files...
  pat=$1; shift
  for f in "$@"; do [ -f "$f" ] && grep -Eqi -- "$pat" "$f" && return 0; done
  return 1
}

# --- every fixture ---------------------------------------------------------------
check "never-overwrite invariant" sh "$ROOT/tests/invariant/checksum.sh" verify "$P" "$M"
check "config exists" test -f "$P/.groma/config.yaml"
check "config validates" sh "$ROOT/skills/groma/scripts/validate-config.sh" "$P/.groma/config.yaml" --catalog "$ROOT/skills/groma-skills/catalog.yaml"
for d in README vision concept architecture data-model glossary risks; do
  # a slot may be filled by a pre-existing file (django: docs/architecture.md)
  check "docs/$d.md present" test -f "$P/docs/$d.md"
done
check "ADR index present" test -f "$P/docs/adr/README.md"
check "AGENTS.md present" test -f "$P/AGENTS.md"
new_files=$( (cd "$P" && find docs AGENTS.md .groma -type f 2>/dev/null) | while read -r f; do grep -q "  ./$f\$" "$M" || echo "$P/$f"; done)
leftover=""
for f in $new_files; do
  if grep -q '{{' "$f" 2>/dev/null; then leftover="$leftover ${f#"$P"/}"; fi
done
if [ -z "$leftover" ]; then ok "no unresolved {{placeholders}} in new files"; else no "unresolved placeholders in:$leftover"; fi

findings=""
for f in "$P"/docs/_groma/findings-*.md; do [ -f "$f" ] && findings=$f && break; done

# --- per fixture -------------------------------------------------------------------
case "$FX" in
  empty)
    check "project_type greenfield" has "$P/.groma/config.yaml" '^project_type: *greenfield'
    check "seed ADR 0001" test -f "$P/docs/adr/0001-record-architecture-decisions.md"
    check "seed ADR 0002" test -f "$P/docs/adr/0002-adopt-groma-docs-structure.md"
    check "vision uses interview answer" has "$P/docs/vision.md" 'recipe'
    ;;
  node-prisma)
    check "project_type brownfield" has "$P/.groma/config.yaml" '^project_type: *brownfield'
    check "findings report" test -n "$findings"
    n=$(grep -l '^status: *proposed' "$P"/docs/adr/0*.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "$n" -ge 2 ]; then ok "at least 2 proposed ADRs ($n)"; else no "at least 2 proposed ADRs (found $n)"; fi
    check "data model has User and Order" sh -c "grep -q User '$P/docs/data-model.md' && grep -q Order '$P/docs/data-model.md'"
    check "data model tagged EXTRACTED" has "$P/docs/data-model.md" 'EXTRACTED'
    ;;
  java-flyway)
    check "project_type brownfield" has "$P/.groma/config.yaml" '^project_type: *brownfield'
    check "harvested legacy ADR listed in index" has "$P/docs/adr/README.md" 'doc/architecture/decisions/0001-use-postgresql'
    check "new ADRs continue numbering (no second 0001)" sh -c "! ls '$P'/docs/adr/0001-* >/dev/null 2>&1 || grep -q 'record-architecture' '$P/docs/adr/README.md'"
    check "email drift reported" any_has 'email' "$findings" "$P/docs/data-model.md" "$P/docs/risks.md"
    ;;
  python-django-stale-docs)
    check "stale architecture doc reported" any_has 'architecture\.md.*stale|stale.*architecture\.md' "$findings"
    check "snippet for existing CLAUDE.md" any_has '@AGENTS\.md' "$findings"
    check "existing architecture.md kept as slot" has "$P/docs/README.md" 'architecture\.md'
    ;;
  go-no-db)
    check "data model not applicable" has "$P/docs/data-model.md" 'not applicable'
    ;;
esac

[ "$fails" -eq 0 ]
