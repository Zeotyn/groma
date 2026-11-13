## 1. Tests first

- [x] 1.1 bats for the report script: parses a recorded `claude -p` JSON result, writes the TSV row, prints totals and the baseline difference

## 2. Report

- [x] 2.1 `run.sh` with JSON output per fixture; report script; totals and baseline difference
- [x] 2.2 Nightly workflow uploads the report as an artifact (the on-demand evals workflow; there is no nightly run since f006)
- [ ] 2.3 Full eval run; commit the result as `tests/evals/reports/baseline.tsv` (needs one eval run (cost), not run: `scripts/test.sh evals`, then copy that day's report to `tests/evals/reports/baseline.tsv`; up to 24 USD)

## 3. Docs

- [ ] 3.1 `docs/architecture.md` testing part; how to read the report; CHANGELOG `[Unreleased]` (CHANGELOG by integrator)
