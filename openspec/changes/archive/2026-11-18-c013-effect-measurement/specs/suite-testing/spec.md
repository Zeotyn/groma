## ADDED Requirements

### Requirement: Effect eval
An effect eval SHALL run the same scripted task on a fixture with and without groma's setup, at least three times per side, and SHALL report per side the median tokens, cost and turns and the acceptance-test pass rate.

#### Scenario: Comparison report
- **WHEN** the effect eval finishes
- **THEN** `tests/evals/reports/effect-<date>.tsv` lists both sides with median tokens, cost, turns and pass rate, and the output names the difference
