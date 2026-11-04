## ADDED Requirements

### Requirement: Repository reminder toggles
The config validator SHALL accept `reminders.uncommitted` and `reminders.unpushed` with the values `true` and `false`, and SHALL report other values as errors with the line number.

#### Scenario: Invalid toggle
- **WHEN** the config contains `unpushed: sometimes`
- **THEN** validation fails with the line number and "must be true or false"
