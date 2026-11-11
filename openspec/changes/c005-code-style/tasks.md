## 1. Tests and fixtures first

- [x] 1.1 Fixtures: style configs in node-prisma, editorconfig drift in python-django-stale-docs, style section in java-flyway `CONTRIBUTING.md`; regenerate with `tests/fixtures/generate.sh`
- [x] 1.2 `tests/scripts/style-drift.bats`: each editorconfig property, section globs, untracked files ignored, `unchecked` via workflow, package.json script and Makefile, no `.editorconfig` → empty report
- [x] 1.3 Structure check for `code-style-tools.md` (required columns, one default per stack and role, templates referenced exist)

## 2. Data and templates

- [x] 2.1 `skills/groma-lay-out/references/code-style-tools.md` with the seed rows from design D2
- [x] 2.2 `templates/code-style/<tool>/` configs for EditorConfig, Prettier, ESLint, Ruff, rustfmt, RuboCop, shfmt
- [x] 2.3 `templates/docs/code-style.md` and the slot row in `references/doc-slots.md` (fill patterns per U)

## 3. Scripts and skills

- [x] 3.1 `skills/groma-survey/scripts/style-drift.sh` per D3; shellcheck clean
- [ ] 3.2 groma-survey SKILL: tool detection from the table, convention sampling per D4, drift and unchecked findings
- [ ] 3.3 groma SKILL interview: style tools question per the orchestration delta; setup step per D5 through the install consent flow
- [ ] 3.4 groma-lay-out SKILL: write the doc (brownfield from survey, greenfield from interview), ADR per chosen tool
- [ ] 3.5 groma-agents AGENTS.md template: pointer line and check commands
- [ ] 3.6 groma-loop SKILL and `review-prompt.md`: checks in the tests gate, doc as project rules with severities
- [ ] 3.7 `methodologies.md`: code-style context line; `upgrades.md` row 0.3.0
- [ ] 3.8 `scripts/test.sh` green

## 4. Evals

- [ ] 4.1 Assertions: `docs/code-style.md` exists with tools table on node-prisma, drift finding on python-django, CONTRIBUTING fills the slot on java-flyway, invariant holds on all
- [ ] 4.2 Greenfield eval with answers file choosing TypeScript: configs and ADRs created, install command in `.groma/install.sh`

## 5. Docs

- [ ] 5.1 groma's own `docs/code-style.md` (POSIX sh, shellcheck, SC2015 rule, Markdown tables, English) and AGENTS.md pointer
- [ ] 5.2 `docs/architecture.md`, `docs/concept.md`, `docs/glossary.md`; ADRs for D1 and D3; ADR index
- [ ] 5.3 README: code style in the Survey/Align/Build table; CHANGELOG `[Unreleased]`
