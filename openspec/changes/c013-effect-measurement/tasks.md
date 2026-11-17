## 1. Setup

- [x] 1.1 Pick fixture and task; write the task prompt and its acceptance test
- [x] 1.2 Effect mode in `tests/evals/` with N runs per side and a cost cap stated up front

## 2. Measure

- [x] 2.1 Run; record medians, spread and pass rates in the report and here
- [x] 2.2 `scripts/test.sh` green

## 3. Docs

- [x] 3.1 `docs/vision.md` success measure; README statement only if the result supports it; CHANGELOG `[Unreleased]`

## Result (2026-11-17)

`tests/evals/reports/effect-2026-11-17.tsv`, go-no-db, task "add `-l`", 3 runs per side, CLI default model; setup `/groma` USD 1.65 (not in the medians).

| Side | Median cost | Spread | Median turns | Median output tokens | Pass |
|---|---|---|---|---|---|
| without | USD 0.086 | 0.060 to 0.241 | 8 | 1579 | 3/3 |
| with | USD 0.548 | 0.443 to 0.666 | 30 | 10404 | 3/3 |

No saving on this task. With groma's setup the agent follows the process AGENTS.md describes: an OpenSpec change, a proposed ADR, doc updates with `last_reviewed`, table-driven tests, the docs-impact gate. Without it, the agent edits `main.go` and README and stops. The pass rate is equal, so the extra cost buys process and tests the acceptance test does not ask for. The README states no effect claim. A fixture whose docs hold a decision the code does not show is the follow-up (design D1).
