## 1. Tests first

- [ ] 1.1 bats for the report script: parses a recorded `claude -p` JSON result, writes the TSV row, prints totals and the baseline difference

## 2. Report

- [ ] 2.1 `run.sh` with JSON output per fixture; report script; totals and baseline difference
- [ ] 2.2 Nightly workflow uploads the report as an artifact
- [ ] 2.3 Full eval run; commit the result as `tests/evals/reports/baseline.tsv`

## 3. Docs

- [ ] 3.1 `docs/architecture.md` testing part; how to read the report; CHANGELOG `[Unreleased]`
