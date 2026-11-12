## MODIFIED Requirements

### Requirement: Agent evals
Evals SHALL run groma headless against each fixture and SHALL assert the expected outcomes: classification, mandatory docs present, ADRs present or proposed, stale docs reported, data-model tags present. Evals SHALL run only on demand (a manual workflow run, or a pull request labeled `eval`) and in a milestone's release gate, never on a schedule and not on every PR, because every run costs API tokens.

#### Scenario: Greenfield eval
- **WHEN** the eval runs on the empty fixture with scripted interview answers
- **THEN** it asserts all mandatory docs and seed ADRs exist and `.groma/config.yaml` is valid

#### Scenario: No scheduled runs
- **WHEN** a day passes without anyone starting the evals workflow or labeling a pull request `eval`
- **THEN** no eval run starts and no API tokens are spent
