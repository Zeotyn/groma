## 1. Tests and fixture first

- [x] 1.1 Fixture `living-docs` in `tests/fixtures/` (git history: docs with `sources`, an OpenSpec change touching code, a design with two decisions, one with Alternatives)
- [x] 1.2 `tests/scripts/docs-impact.bats`: impact line, doc updated in change, ADR docs skipped, docs without sources skipped, justified and unjustified `Docs:` lines, `adr` line and `origin` coverage, `marked` and `off` modes, base from proposal commit and working-tree fallback, `--gate` exit codes
- [x] 1.3 bats cases for `validate-config.sh` (`docs.gate`, `docs.adr_from`, closest match) and `status.sh` (docs reminder priority, pending ADR after archive)

## 2. Script

- [x] 2.1 `skills/groma-lay-out/scripts/docs-impact.sh` per design D1, D2, D5; shellcheck clean
- [x] 2.2 `validate-config.sh` and `skills/groma/templates/config.yaml`: `docs.gate`, `docs.adr_from`
- [x] 2.3 `status.sh`: docs reminders, respecting `docs.gate`

## 3. Skills and templates

- [x] 3.1 `adr-template.md`: `origin` key; groma-lay-out SKILL: writing ADR candidates from a change design
- [x] 3.2 groma-loop SKILL, `review-prompt.md`, `methodology-adapters.md`: docs gate at verify, docs sync and `strict` at archive
- [x] 3.3 `methodologies.md` (OpenSpec): `rules.proposal`, `rules.tasks`, `rules.design` when groma created the config, snippet otherwise
- [x] 3.4 AGENTS.md template line; `upgrades.md` row for 0.2.0
- [x] 3.5 Structure check and `scripts/test.sh` green

## 4. Dogfood

- [ ] 4.1 Add the three rules to this repository's `openspec/config.yaml`
- [ ] 4.2 ADRs for C002 D1–D6 (`accepted`, `origin: c002-review-loop#Dn`), proposed ADRs for C003 D1–D7, ADRs for C004 D1–D5
- [ ] 4.3 `docs/architecture.md`, `docs/concept.md`, `docs/glossary.md`: groma-loop, lifecycle reminders, living docs; ADR index
- [ ] 4.4 `docs-impact.sh --gate openspec/changes/c004-living-docs` exits 0
- [ ] 4.5 Eval: loop eval asserts a docs finding when a fixture change skips its doc update

## 5. Docs

- [ ] 5.1 README: living-docs section with the gate table
- [ ] 5.2 CHANGELOG `[Unreleased]`: Added entry
- [ ] 5.3 `docs/data-model.md`: `docs.gate` and `docs.adr_from` in the config entity, `origin` in the ADR entity
