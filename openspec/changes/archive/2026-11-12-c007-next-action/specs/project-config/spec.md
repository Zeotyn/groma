## ADDED Requirements

### Requirement: Next-action settings
The `next` section of `.groma/config.yaml` SHALL accept `hook` (`on`, `off`; default `off` until the user agrees) and `reshow_minutes` (integer ≥ 0; 0 shows only on change). The validator SHALL reject other values with the line number.

#### Scenario: Negative reshow
- **WHEN** the config contains `reshow_minutes: -5`
- **THEN** validation fails with the line number
