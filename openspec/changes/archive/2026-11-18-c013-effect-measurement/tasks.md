## 1. Setup

- [x] 1.1 Pick fixture and task; write the task prompt and its acceptance test
- [x] 1.2 Effect mode in `tests/evals/` with N runs per side and a cost cap stated up front

## 2. Measure

- [x] 2.1 Run; record medians, spread and pass rates in the report and here (re-run 2026-11-18, see Result)
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

Re-run 2026-11-18: `tests/evals/reports/effect-2026-11-18.tsv`, fixture go-no-db, task "add `-l`", 3 runs per side, CLI default model, every run and the setup on `claude-opus-5-5`. Setup `/groma` USD 1.7694 (not in the medians). Both sides load the operator's user-level settings, CLAUDE.md and skills (limit in the report header).

| Side | Median cost | Spread | Median turns | Median output tokens | Median duration | Pass | Permission denials |
|---|---|---|---|---|---|---|---|
| without | USD 0.0642 | 0.0641 to 0.2291 | 6 | 1334 | 13 s | 3/3 | 1, 0, 0 |
| with | USD 0.6213 | 0.5348 to 0.6317 | 35 | 11714 | 105 s | 3/3 | 4, 4, 7 |

Observed: equal pass rate; the "with" side's median cost is USD 0.5571 higher, with 29 more turns and about 10k more output tokens. Its runs wrote an OpenSpec change, an ADR and doc updates, which the acceptance test does not check. The "with" side still met permission denials, mostly compound shell commands (heredocs, `set -e` blocks, `git add -A && git commit`) and one `git rebase`; the agents worked around them and every run ended with `success`. How the denials shift cost is not measured. One fixture, three runs per side: no saving is shown for this task, and the README makes no effect claim.

The first run (2026-11-17) is invalid: the "with" side was denied `git switch`, `git add`, `git commit`, `mkdir` and `sed`. Its report was deleted and its figures are not used.
