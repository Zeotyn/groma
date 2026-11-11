## 1. Tests and fixtures first

- [x] 1.1 Fixture histories in `tests/fixtures/`: PR-merge history, squash history, linear conventional history, empty repo
- [x] 1.2 `tests/scripts/git-practice.bats`: each recommendation rule with evidence lines, 70 percent threshold, main-branch detection, empty repo
- [x] 1.3 bats for `validate-config.sh`: `git` keys, closest match
- [x] 1.4 bats for the integration sequences in a temp repo: rebase leaves no merge commit, squash makes one commit, conflict aborts with refs unchanged

## 2. Scripts and config

- [x] 2.1 `skills/groma-detect/scripts/git-practice.sh` per D4; shellcheck clean
- [x] 2.2 `skills/groma/templates/config.yaml` `git` section; `validate-config.sh` support
- [x] 2.3 `docs-impact.sh`: base from `merge-base` on change branches, proposal-commit fallback

## 3. Skills and templates

- [x] 3.1 groma SKILL interview: integration strategy and push questions with recommendation and evidence
- [x] 3.2 groma-agents AGENTS.md template: "Git workflow" section per strategy (D1, D2)
- [x] 3.3 groma-loop SKILL: branch at start, commit per unit, archive commit, integrate, push policy, escalations (D3, D5); `methodology-adapters.md` archive step
- [x] 3.4 `upgrades.md` row 0.3.0
- [x] 3.5 `scripts/test.sh` green

## 4. Evals

- [x] 4.1 Loop eval with `integrate: rebase`: branch exists after the run, `main` has no new merge commit, push asked
- [x] 4.2 Loop eval with a forced conflict: escalation names the file, refs unchanged

## 5. Docs

- [x] 5.1 This repository: `.groma/config.yaml` `git` section (`rebase`, `push: ask`) and the AGENTS.md "Git workflow" section
- [x] 5.2 `docs/architecture.md`, `docs/concept.md`, `docs/glossary.md`; ADRs for D1 and D3; ADR index
- [x] 5.3 README: git workflow in the configuration section; CHANGELOG `[Unreleased]`
- [x] Docs: `docs/vision.md` unchanged, because the README change documents configuration and the loop's git steps, not goals
- [x] Docs: `docs/code-style.md` unchanged, because the new scripts and tests follow the documented conventions and add no new one
