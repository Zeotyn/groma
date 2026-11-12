## 1. Tests first

- [ ] 1.1 `tests/scripts/conventions.bats`: new format accepted (`c4-x`, `m3-x`, `m3-spike-x`, `m3-fix-x`), padded and `d` names rejected unless in the baseline, duplicates by `<type><N>` and full `m` name, next id without padding, old padded archive counted, `next-change-id.sh m` from roadmap headings and `m<N>-` names, `d` unknown, `--suggest-migration` output for names and an umbrella milestone, section without markers reported
- [ ] 1.2 roadmap bats: only marker blocks rewritten, hand-written text byte-identical, changes grouped by prefix, `Milestone:` fallback for baseline names, section without markers untouched
- [ ] 1.3 `tests/scripts/status.bats` and `next.bats`: gate from the roadmap release-gate checklist, no gate while an `m<N>-` change is active, old umbrella gate still works from the baseline, codeless types `s`, `m<N>-spike-`, `r`
- [ ] 1.4 `tests/scripts/git-integrate.bats`: commit types from prefix and type word

## 2. Scripts

- [ ] 2.1 `lib-changes.sh`: types without `d`, drop `config_digits`, helpers for milestone number, type word and spike detection
- [ ] 2.2 `next-change-id.sh` (same flags, no padding, `m` from roadmap and names) and `check-conventions.sh` (new pattern, duplicates, missing markers, `--suggest-migration`) per D4, D7
- [ ] 2.3 `roadmap.sh` per D5; `status.sh` and `next.sh` per D6
- [ ] 2.4 `validate-config.sh`: warn on `conventions.changes.digits`; shellcheck clean for all touched scripts

## 3. Text and templates

- [ ] 3.1 `references/conventions.md`: rule text, type table with reasons, mapping table (OpenSpec, Spec Kit, BMAD, GSD), migration section
- [ ] 3.2 `methodologies.yaml` rule strings, `references/methodologies.md`, groma-methodology SKILL, AGENTS.md template line
- [ ] 3.3 `templates/roadmap-section.md` replaces `templates/milestone-proposal.md`; groma-lay-out roadmap slot if it references the old template
- [ ] 3.4 groma-loop `methodology-adapters.md` and groma-agents `git-strategies.md`: commit type from prefix and type word
- [ ] 3.5 `upgrades.md` row: baseline written, `--suggest-migration` snippets into the findings report, `digits` ignored

## 4. Evals

- [ ] 4.1 Fixture `loop-openspec`: `c001-add-farewell` → `c1-add-farewell`; prompts and `assert.sh` (commit subject); run only the affected fixture once, with the user's consent for the cost

## 5. Docs

- [ ] 5.1 `docs/glossary.md`, `docs/concept.md`, `docs/architecture.md`, README "Conventions groma sets up"; ADRs for D1 to D7 where they have alternatives; ADR index; CHANGELOG `[Unreleased]` with the breaking ID format
- [ ] 5.2 This repository: add `.groma/conventions-baseline.txt` with all current names so M004 finishes under the old names; new rule from M5
- [ ] 5.3 `scripts/test.sh` green; `openspec validate --all --strict`
