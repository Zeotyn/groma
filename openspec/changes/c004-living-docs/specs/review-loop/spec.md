## ADDED Requirements

### Requirement: Docs gate in the loop
At verify, groma-loop SHALL run the docs impact report for the change when `docs.gate` is `review` or `strict` and add each line as a high finding. At archive, groma-loop SHALL run the docs sync after the spec sync; with `strict` it SHALL escalate instead of archiving while the report is not empty.

#### Scenario: Verify finds a stale doc
- **WHEN** verify runs for a change that modified `skills/` and `docs/architecture.md` (sources `skills/`) is unchanged
- **THEN** the verify record contains a high finding for `docs/architecture.md`, answered by updating the doc or by adding a justified `Docs:` task line
