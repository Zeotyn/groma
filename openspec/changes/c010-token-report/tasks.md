## 1. Tests first

- [x] 1.1 bats for the report script: parses a recorded `claude -p` JSON result, writes the TSV row, prints totals and the baseline difference

## 2. Report

- [x] 2.1 `run.sh` with JSON output per fixture; report script; totals and baseline difference
- [x] 2.2 Nightly workflow uploads the report as an artifact (the on-demand evals workflow; there is no nightly run since f006)
- [x] 2.3 Full eval run; commit the result as `tests/evals/reports/baseline.tsv` (2026-11-13, main at 4acb1c0 before C011: 8 fixtures, 10.38 USD, 164,705 output and 12.3 M cache-read tokens; 6 of 8 passed, the 2 failures were strict assertions, fixed by F007 and re-asserted green on the same run)
- [ ] 2.4 Record the token difference of C011's diet against the baseline (C011 before/after), and `claude plugin details` estimates

## 3. Docs

- [x] 3.1 `docs/architecture.md` testing part; how to read the report; CHANGELOG `[Unreleased]` (CHANGELOG by integrator)
- [x] Docs: `docs/code-style.md` unchanged, because the new script follows its existing conventions (POSIX sh, awk parsing, tab-separated output ending in a summary line, one bats file per script)
