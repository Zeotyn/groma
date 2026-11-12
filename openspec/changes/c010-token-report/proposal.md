Milestone: m004

## Why

groma claims to be sparing with tokens: deterministic scripts instead of agent reasoning, an interview that asks only what it cannot see, a reviewer that sees only the diff. Nothing measures it. The eval runs already call `claude -p`, whose JSON result carries token counts and cost, and throw them away. Without a baseline, every later optimization is a claim again.

## What Changes

- `tests/evals/run.sh` runs `claude -p` with JSON output and writes one row per fixture to `tests/evals/reports/<date>.tsv`: fixture, input tokens, output tokens, cache read, cache write, cost in USD, turns, duration.
- A summary line prints the totals after the run.
- The first full run after this change is committed as the baseline `tests/evals/reports/baseline.tsv`; later runs print the difference per fixture against it.
- The nightly eval workflow uploads the report as an artifact.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `suite-testing`: agent evals report tokens and cost per fixture against a baseline.

## Docs impact

`docs/architecture.md` (testing part); README "Contributing" or CONTRIBUTING.md on how to read the report.

## Impact

`tests/evals/run.sh`, a small report script, `.github/workflows/evals.yml`. The baseline run costs one eval run (up to about 24 USD).
