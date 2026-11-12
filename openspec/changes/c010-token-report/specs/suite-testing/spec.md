## ADDED Requirements

### Requirement: Token report
Each eval run SHALL write, per fixture, the input, output and cache tokens, the cost in USD, the number of turns and the duration to a report file, and SHALL print the totals. When a committed baseline exists, the run SHALL print the difference per fixture against it.

#### Scenario: Report after a run
- **WHEN** `scripts/test.sh evals` finishes
- **THEN** `tests/evals/reports/<date>.tsv` has one row per fixture with tokens and cost, and the output ends with the totals

#### Scenario: Comparison with the baseline
- **WHEN** `tests/evals/reports/baseline.tsv` exists and a run finishes
- **THEN** each fixture's line shows its token and cost difference against the baseline
