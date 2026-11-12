## 1. Spike and tests first

- [x] 1.1 Spike: Copilot CLI `agentStop` hook with stdout and with a message field; record whether the user sees it and whether a new turn starts; set copilot's adapter status from the result (`tests/manual/copilot-agentstop-2026-11-12.md`: stdout and `systemMessage` ignored, stderr with exit 2 shown without a new turn in headless mode; interactive TUI unverified, so `experimental` with format `stderr-exit2`)
- [x] 1.2 `tests/scripts/next.bats`: each rung in order with fixtures, nothing → empty output, `git.push: never` skips rung 6, `--short` ≤ 20 chars, `--json` fields, cache hit skips status.sh, cache miss after commit and after working-tree change
- [x] 1.3 bats for the Stop hook wrapper: first show, same line suppressed, changed line shown, reshow after `reshow_minutes`, empty clears state; output is only `systemMessage`, never `decision`
- [x] 1.4 Structure check: every agent in `agents.yaml` has a `hook` entry with a valid status

## 2. Script and data

- [x] 2.1 `skills/groma-methodology/scripts/next.sh` per D2, D3
- [x] 2.2 Stop hook wrapper and `templates/claude-stop-hook.json` per D5
- [x] 2.3 `agents.yaml` hook adapters per D6; self-ignoring `.groma/.cache/` (replaces the `.groma/.gitignore` template, see design D3 notes)
- [x] 2.4 Measure: under 300 ms on this repository with a warm cache; record cold and warm timings here (2026-11-12, 2 active changes, `/usr/bin/time -p next.sh --short .`: cold 0.66 to 0.79 s, warm 0.06 to 0.21 s)
- [x] 2.5 `next` config section, validator support

## 3. CLI and skills

- [x] 3.1 `cli/next.js` and `groma next` in `main.js` with `--short`, `--json`; node tests
- [x] 3.2 groma-agents SKILL: one offer for hook and status-line snippet; AGENTS.md fallback line
- [x] 3.3 `upgrades.md` row 0.3.0; `scripts/test.sh` green

## 4. Evals

- [x] 4.1 Claude headless run with the Stop hook: the transcript shows one `▶ Next:` line, no extra agent turn (`tests/manual/claude-stop-hook-2026-11-12.md`: one notice, `num_turns: 1`; second run within 30 minutes shows none)

## 5. Docs

- [x] 5.1 `docs/architecture.md`, `docs/concept.md`, `docs/glossary.md`; proposed ADRs for D1, D2, D4 with `origin`; ADR index
- [x] 5.2 README: next action section with status-line snippet; CHANGELOG `[Unreleased]`
