## ADDED Requirements

### Requirement: Git settings validation
The config validator SHALL accept the `git` keys `integrate`, `branch_per_change`, `commits` and `push` with their allowed values, and SHALL reject other values with the line number and the closest valid value.

#### Scenario: Typo in strategy
- **WHEN** the config contains `integrate: rebsae`
- **THEN** validation fails with the line number and "did you mean rebase?"
