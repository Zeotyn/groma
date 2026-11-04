## 1. Tests first

- [x] 1.1 bats cases in `tests/scripts/freshness.bats`: accepted ADR fresh after code change; proposed ADR older than 30 days stale with date; proposed ADR younger fresh; `--adr-days 0` flags every proposed ADR; index with `sources: [docs/]` not stale; missing source broken; source under `openspec/changes/` broken; summary has trailing `broken=`

## 2. Script

- [x] 2.1 `freshness.sh`: ADR branch (`<docs>/adr/*`, `--adr-days`, `date` frontmatter with commit fallback)
- [x] 2.2 `freshness.sh`: drop sources inside the docs folder; review-date rule only when none remain
- [x] 2.3 `freshness.sh`: `broken` kind for missing and change-folder sources, summary field, header comment updated
- [x] 2.4 `shellcheck -s sh` and `scripts/test.sh` green

## 3. Skills and templates

- [x] 3.1 groma-survey SKILL step 5 and `templates/findings.md`: `broken` lines become findings with "fix `sources` in frontmatter"
- [x] 3.2 groma-lay-out SKILL step and `references/doc-slots.md` placeholder `{{sources}}`: code and config paths only, never docs or change folders

## 4. Docs

- [x] 4.1 groma's own `docs/concept.md` and `docs/risks.md`: replace change-folder sources with code paths
- [x] 4.2 Run `freshness.sh .` on this repository; expected: no ADR and no `docs/README.md` line stale, `broken=0`; note remaining stale docs as input for C004
  - Result: `stale=4 fresh=13 unknown=0 broken=0`. Stale, input for C004: `docs/architecture.md`, `docs/concept.md`, `docs/glossary.md` (`skills/` changed), `docs/data-model.md` (`skills/groma-lay-out/references/doc-slots.md` changed). `docs/vision.md` also listed an archived change path; fixed here.
- [x] 4.3 CHANGELOG `[Unreleased]`: Fixed entry
