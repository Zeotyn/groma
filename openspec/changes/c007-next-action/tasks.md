## 1. Spike and tests first

- [ ] 1.1 Spike: Copilot CLI `agentStop` hook with stdout and with a message field; record whether the user sees it and whether a new turn starts; set copilot's adapter status from the result
- [ ] 1.2 `tests/scripts/next.bats`: each rung in order with fixtures, nothing → empty output, `git.push: never` skips rung 6, `--short` ≤ 20 chars, `--json` fields, cache hit skips status.sh, cache miss after commit and after working-tree change
- [ ] 1.3 bats for the Stop hook wrapper: first show, same line suppressed, changed line shown, reshow after `reshow_minutes`, empty clears state; output is only `systemMessage`, never `decision`
- [ ] 1.4 Structure check: every agent in `agents.yaml` has a `hook` entry with a valid status

## 2. Script and data

- [ ] 2.1 `skills/groma-methodology/scripts/next.sh` per D2, D3
- [ ] 2.2 Stop hook wrapper and `templates/claude-stop-hook.json` per D5
- [ ] 2.3 `agents.yaml` hook adapters per D6; `.groma/.gitignore` template
- [ ] 2.4 Measure: under 300 ms on this repository with a warm cache; record cold and warm timings here
- [ ] 2.5 `next` config section, validator support

## 3. CLI and skills

- [ ] 3.1 `cli/next.js` and `groma next` in `main.js` with `--short`, `--json`; node tests
- [ ] 3.2 groma-agents SKILL: one offer for hook and status-line snippet; AGENTS.md fallback line
- [ ] 3.3 `upgrades.md` row 0.3.0; `scripts/test.sh` green

## 4. Evals

- [ ] 4.1 Claude headless run with the Stop hook: the transcript shows one `▶ Next:` line, no extra agent turn

## 5. Docs

- [ ] 5.1 `docs/architecture.md`, `docs/concept.md`, `docs/glossary.md`; proposed ADRs for D1, D2, D4 with `origin`; ADR index
- [ ] 5.2 README: next action section with status-line snippet; CHANGELOG `[Unreleased]`
