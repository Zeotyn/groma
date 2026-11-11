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

# --- review loop fixture: its own checks, the loop edits code on purpose ----------
if [ "$FX" = loop-openspec ]; then
  arch=""
  for d in "$P"/openspec/changes/archive/*-c001-add-farewell; do [ -d "$d" ] && arch=$d; done
  check "change archived" test -n "$arch"
  check "change no longer active" test ! -d "$P/openspec/changes/c001-add-farewell"
  check "spec synced to openspec/specs/farewell" test -f "$P/openspec/specs/farewell/spec.md"
  n=0
  for f in "$arch"/reviews/*-round-*.md; do [ -f "$f" ] && n=$((n + 1)); done
  if [ "$n" -ge 2 ]; then ok "review records for apply and verify ($n)"; else no "review records for apply and verify (found $n)"; fi
  unanswered=0
  for f in "$arch"/reviews/*-round-*.md; do
    [ -f "$f" ] || continue
    u=$(awk -F'|' '/^\| *[A-Z][0-9]+ *\|/ { r = $7; gsub(/^ +| +$/, "", r); if (r !~ /^(fixed|rejected)/) c++ } END { print c + 0 }' "$f")
    unanswered=$((unanswered + u))
  done
  if [ "$unanswered" -eq 0 ]; then ok "every finding answered"; else no "$unanswered finding(s) without fixed/rejected"; fi
  leftovers=0
  for f in "$arch"/reviews/.prompt-* "$arch"/reviews/.raw-*; do [ -e "$f" ] && leftovers=$((leftovers + 1)); done
  if [ "$leftovers" -eq 0 ]; then ok "no prompt/raw leftovers"; else no "$leftovers prompt/raw leftovers"; fi
  check "farewell implemented" grep -rq "Goodbye" "$P/src"
  check "tests pass" sh -c "cd '$P' && node --test >/dev/null 2>&1"
  check "all tasks ticked" sh -c "! grep -q '^- \[ \]' '$arch/tasks.md'"
  check "reviewer recorded" grep -rqi "reviewer: claude:sonnet" "$arch/reviews"
  # docs gate: the change adds src/farewell.js but plans no doc update
  check "docs finding for docs/architecture.md in a review record" \
    sh -c "grep -h '^| *[A-Z][0-9]' '$arch'/reviews/*-round-*.md | grep -q 'docs/architecture.md'"
  check "docs impact closed (doc updated or Docs: task line)" \
    sh -c "grep -qi farewell '$P/docs/architecture.md' || grep -q 'Docs: .*docs/architecture.md.* unchanged, because .' '$arch/tasks.md'"
  # git steps with the defaults: branch per change, rebase, push ask (the fixture has no remote)
  check "change branch exists after the run" git -C "$P" rev-parse -q --verify refs/heads/c001-add-farewell
  check "main was fast-forwarded to the branch" sh -c "[ \"\$(git -C '$P' rev-parse main)\" = \"\$(git -C '$P' rev-parse c001-add-farewell)\" ]"
  check "main has no merge commit" sh -c "[ \"\$(git -C '$P' rev-list --merges --count main)\" -eq 0 ]"
  check "unit commit in conventional style" sh -c "git -C '$P' log --format=%s main | grep -Eq '^feat\(c001-add-farewell\): '"
  check "archive commit" sh -c "git -C '$P' log --format=%s main | grep -q '^docs(openspec): archive c001-add-farewell'"
  check "working tree clean at the end" sh -c "[ -z \"\$(git -C '$P' status --porcelain)\" ]"
  check "summary mentions the push (asked, or no remote)" grep -Eqi 'push' "${M%.manifest}.log"
  [ "$fails" -eq 0 ]
  exit
fi

# --- forced integration conflict: the loop aborts and escalates, refs unchanged ------
if [ "$FX" = conflict-loop-openspec ]; then
  LOG="${M%.manifest}.log"
  main0=$(cat "${M%.manifest}.main" 2>/dev/null || true)
  check "main points to the commit from before the run" sh -c "[ -n '$main0' ] && [ \"\$(git -C '$P' rev-parse main)\" = '$main0' ]"
  check "no rebase or merge in progress" sh -c "[ ! -d '$P/.git/rebase-merge' ] && [ ! -d '$P/.git/rebase-apply' ] && [ ! -f '$P/.git/MERGE_HEAD' ]"
  check "working tree clean after the abort" sh -c "[ -z \"\$(git -C '$P' status --porcelain)\" ]"
  check "still on the change branch" sh -c "[ \"\$(git -C '$P' branch --show-current)\" = c001-add-farewell ]"
  check "branch holds the unit and archive commits" sh -c "git -C '$P' log --format=%s c001-add-farewell | grep -q '^docs(openspec): archive c001-add-farewell'"
  check "main has no merge commit" sh -c "[ \"\$(git -C '$P' rev-list --merges --count main)\" -eq 0 ]"
  check "escalation message" grep -q "groma-loop stopped" "$LOG"
  check "escalation names the conflicting file" grep -q "openspec/changes/c001-add-farewell/tasks.md" "$LOG"
  check "no force push attempted" sh -c "! grep -Eq -- '--force' '$LOG'"
  [ "$fails" -eq 0 ]
  exit
fi

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
# code-style slot: docs/code-style.md, or an existing style guide linked from the docs index
check "code-style slot filled" sh -c "test -f '$P/docs/code-style.md' || grep -Eqi 'code.style|CONTRIBUTING|STYLEGUIDE' '$P/docs/README.md'"
check "AGENTS.md points to the code-style doc" has "$P/AGENTS.md" 'code-style|CONTRIBUTING|STYLEGUIDE'
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
    # greenfield TypeScript with Prettier and ESLint confirmed in the interview
    check "code-style doc exists" test -f "$P/docs/code-style.md"
    check ".editorconfig created" test -f "$P/.editorconfig"
    check ".prettierrc.json created" test -f "$P/.prettierrc.json"
    check "eslint.config.js created" test -f "$P/eslint.config.js"
    check "tools table lists Prettier and typescript-eslint" sh -c "grep -qi prettier '$P/docs/code-style.md' && grep -qi 'typescript-eslint' '$P/docs/code-style.md'"
    check "ADR Use Prettier accepted" sh -c "grep -li 'use prettier' '$P'/docs/adr/0*.md | xargs grep -lq '^status: *accepted'"
    check "ADR Use typescript-eslint accepted" sh -c "grep -liE 'use (typescript-)?eslint' '$P'/docs/adr/0*.md | xargs grep -lq '^status: *accepted'"
    check "install command pending in .groma/install.sh" has "$P/.groma/install.sh" 'npm i -D .*prettier|npm i -D .*eslint'
    check "AGENTS.md lists the check commands" sh -c "grep -q 'prettier --check' '$P/AGENTS.md' && grep -q 'eslint' '$P/AGENTS.md'"
    check "openspec context has the code-style line" has "$P/openspec/config.yaml" 'Code style lives in docs/code-style.md'
    ;;
  node-prisma)
    check "project_type brownfield" has "$P/.groma/config.yaml" '^project_type: *brownfield'
    check "findings report" test -n "$findings"
    n=$(grep -l '^status: *proposed' "$P"/docs/adr/0*.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "$n" -ge 2 ]; then ok "at least 2 proposed ADRs ($n)"; else no "at least 2 proposed ADRs (found $n)"; fi
    check "data model has User and Order" sh -c "grep -q User '$P/docs/data-model.md' && grep -q Order '$P/docs/data-model.md'"
    check "data model tagged EXTRACTED" has "$P/docs/data-model.md" 'EXTRACTED'
    check "code-style doc created" test -f "$P/docs/code-style.md"
    check "tools table has Prettier with .prettierrc" sh -c "grep -i prettier '$P/docs/code-style.md' | grep -q '\.prettierrc'"
    check "tools table has ESLint with eslint.config.js and npm run lint" sh -c "grep -i eslint '$P/docs/code-style.md' | grep -q 'eslint.config.js' && grep -q 'npm run lint' '$P/docs/code-style.md'"
    check "code-style sources list the config files" sh -c "grep -q '\.prettierrc' '$P/docs/code-style.md' && sed -n '/^---$/,/^---$/p' '$P/docs/code-style.md' | grep -q 'eslint.config.js'"
    check "conventions tagged INFERRED or EXTRACTED" has "$P/docs/code-style.md" 'INFERRED|EXTRACTED'
    check "prettier unchecked finding" any_has 'prettier.*(unchecked|CI|script)' "$findings"
    check "no tool config created in brownfield" sh -c "! test -f '$P/.editorconfig'"
    ;;
  java-flyway)
    check "project_type brownfield" has "$P/.groma/config.yaml" '^project_type: *brownfield'
    check "harvested legacy ADR listed in index" has "$P/docs/adr/README.md" 'doc/architecture/decisions/0001-use-postgresql'
    check "new ADRs continue numbering (no second 0001)" sh -c "! ls '$P'/docs/adr/0001-* >/dev/null 2>&1 || grep -q 'record-architecture' '$P/docs/adr/README.md'"
    check "email drift reported" any_has 'email' "$findings" "$P/docs/data-model.md" "$P/docs/risks.md"
    # CONTRIBUTING.md has a "Code style" section and fills the slot
    check "no docs/code-style.md next to CONTRIBUTING.md" sh -c "! test -f '$P/docs/code-style.md'"
    check "docs index links CONTRIBUTING.md as the code-style doc" has "$P/docs/README.md" 'CONTRIBUTING\.md'
    check "tools table snippet in the findings" sh -c "grep -qi 'Spotless\|Enforced by tools\|tools table' '$findings'"
    ;;
  python-django-stale-docs)
    check "stale architecture doc reported" any_has 'architecture\.md.*stale|stale.*architecture\.md' "$findings"
    check "snippet for existing CLAUDE.md" any_has '@AGENTS\.md' "$findings"
    check "existing architecture.md kept as slot" has "$P/docs/README.md" 'architecture\.md'
    check "indent_style drift finding with count" any_has 'indent_style.*3|3 files.*indent' "$findings"
    check "drift finding names a tab-indented file" any_has 'shop/(admin|forms|urls)\.py' "$findings"
    check "ruff unchecked finding suggests CI" any_has 'ruff.*(unchecked|CI|script)' "$findings"
    check "code-style doc lists EditorConfig and Ruff" sh -c "grep -qi editorconfig '$P/docs/code-style.md' && grep -qi ruff '$P/docs/code-style.md'"
    ;;
  cli-node-prisma)
    # groma init --yes --print ran first; /groma must reuse its setup
    check "project_type brownfield" has "$P/.groma/config.yaml" '^project_type: *brownfield'
    check "CLI setup kept: methodology openspec" has "$P/.groma/config.yaml" '^methodology: *openspec'
    check "CLI setup kept: steps.config done" has "$P/.groma/config.yaml" '^  config: *done'
    check "CLI install.sh kept" has "$P/.groma/install.sh" 'openspec@[0-9.]+ init'
    check "/groma installed nothing itself: steps.skills still pending" has "$P/.groma/config.yaml" '^  skills: *pending'
    check "/groma installed nothing itself: no second install script" sh -c "! ls '$P'/.groma/install-*.sh >/dev/null 2>&1"
    check "generated skill copies untouched" sh -c "node '$ROOT/bin/groma.js' doctor '$P' | grep -q 'generated files: ok'"
    check "next action recommends npx groma-cli update" sh -c "tail -n 20 '${M%.manifest}.log' | grep -q 'npx groma-cli update'"
    ;;
  go-no-db)
    check "data model not applicable" has "$P/docs/data-model.md" 'not applicable'
    ;;
esac

[ "$fails" -eq 0 ]
