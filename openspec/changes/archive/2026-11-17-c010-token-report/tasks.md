## 1. Tests first

- [x] 1.1 bats for the report script: parses a recorded `claude -p` JSON result, writes the TSV row, prints totals and the baseline difference

## 2. Report

- [x] 2.1 `run.sh` with JSON output per fixture; report script; totals and baseline difference
- [x] 2.2 Nightly workflow uploads the report as an artifact (the on-demand evals workflow; there is no nightly run since f006)
- [x] 2.3 Full eval run; commit the result as `tests/evals/reports/baseline.tsv` (2026-11-13, main at 4acb1c0 before C011: 8 fixtures, 10.38 USD, 164,705 output and 12.3 M cache-read tokens; 6 of 8 passed, the 2 failures were strict assertions, fixed by F007 and re-asserted green on the same run)
- [x] 2.4 Record the token difference of C011's diet against the baseline (C011 before/after), and `claude plugin details` estimates
  - Eval, fixture `empty` (C012 does not touch it), baseline 2026-11-13 (4acb1c0, before C011) vs joint M004 run 2026-11-16 (report 2026-11-16T154408, after C011 and the other M004 changes): output -248, cache read -52,567 (-3.5 %), cost +0.0067 USD. The diet is not measurable in the per-run cost. The other fixtures are not compared here: C012's survey subagent changes them (see c012-survey-subagent task 2.3).
  - `claude plugin details groma@groma` in an isolated `CLAUDE_CONFIG_DIR`, 2026-11-17: always-on ~633 tok (4acb1c0) -> ~491 tok (main 1475894), -22 %. On-invoke grew by ~3k tok in total over the same span (groma ~1.7k -> ~3k, groma-survey ~1.5k -> ~2.2k, groma-agents ~1.9k -> ~2.5k, groma-methodology ~570 -> ~890; the rest within +-100), from the new M004 features (C012, C014, C015, C017), not from C011. The two hooks show as harness-only, no model context cost.

## 3. Docs

- [x] 3.1 `docs/architecture.md` testing part; how to read the report; CHANGELOG `[Unreleased]` (CHANGELOG by integrator)
- [x] Docs: `docs/code-style.md` unchanged, because the new script follows its existing conventions (POSIX sh, awk parsing, tab-separated output ending in a summary line, one bats file per script)
