## ADDED Requirements

### Requirement: Living-docs settings
The `docs` section of `.groma/config.yaml` SHALL accept `gate` (`off`, `remind`, `review`, `strict`; default `review`) and `adr_from` (`design-alternatives`, `marked`, `off`; default `design-alternatives`). The config validator SHALL reject other values with the line number and the closest valid value.

#### Scenario: Typo in gate
- **WHEN** the config contains `gate: strikt`
- **THEN** validation fails with the line number and "did you mean strict?"
