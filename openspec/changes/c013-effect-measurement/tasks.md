## 1. Setup

- [x] 1.1 Pick fixture and task; write the task prompt and its acceptance test
- [x] 1.2 Effect mode in `tests/evals/` with N runs per side and a cost cap stated up front

## 2. Measure

- [ ] 2.1 Run; record medians, spread and pass rates in the report and here (re-run pending, see Result)
- [x] 2.2 `scripts/test.sh` green

## 3. Docs

- [x] 3.1 `docs/vision.md` success measure; README statement only if the result supports it; CHANGELOG `[Unreleased]`

## Review round 1

- [x] R1.1 Remove the figures of the invalid first run from tasks, `docs/vision.md` and CHANGELOG
- [x] R1.2 `effect.sh`: `if` instead of `A && B || C` (SC2015)
- [x] R1.3 `effect.bats`: Go reference solution without tabs in the file (style drift 0)
- [x] R1.4 `effect.sh`: the fixture's commands (`# Requires:` in `effect/<fixture>.sh`) are checked before any API call
- [x] R1.5 `effect.sh`: the report grows in the work folder and moves to the reports folder only at the end
- [x] R1.6 `effect.sh`: `skill-source.sh` runs directly before any API call and keeps exit 3
- [x] R1.7 Contamination by user-level settings, CLAUDE.md and skills stated as a limit in `design.md`, the script header and the report header
- [x] R1.8 Bats: comparison loop with a stub `claude` (`GROMA_EFFECT_SETUP`), checks 4 to 6; budget stops marked per run (`end` column); a `-` in turns or duration left out of medians; model id per run and for the setup recorded
- [x] R1.9 Docs gate: ADR 0074 (proposed) for D1, effect eval in `docs/architecture.md`; code style unchanged
- [x] Docs: `docs/code-style.md` unchanged, because the eval scripts and tests follow its existing rules and add no new convention

## Result

No valid result yet. The first run (2026-11-17, go-no-db, 3 runs per side) is invalid: the "with" side was denied `git switch`, `git add`, `git commit`, `mkdir` and `sed`, which its AGENTS.md asks for, so part of its cost was harness friction. Its report was deleted and the tools were widened (commit 9c6f421); its figures are not used anywhere. A re-run is pending. When it is recorded, the text states what was observed without a causal claim, and includes the setup cost and the model id from the report header and rows.
