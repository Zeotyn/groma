# project-config Specification

## Purpose
Defines the per-project `.groma/config.yaml` that records every choice groma made, so runs are reproducible, reviewable in git and upgradable across suite versions.
## Requirements
### Requirement: Config location and content
groma SHALL store project choices in `.groma/config.yaml` inside the project. The file SHALL contain `schema`, `initialized_with`, `project_type`, `methodology`, `workflow`, `agents`, `skills` (per catalog category) and `docs` settings.

#### Scenario: Config written after interview
- **WHEN** the interview completes
- **THEN** `.groma/config.yaml` exists with `schema: 1`, `initialized_with: groma@<installed version>` and every answer from the interview

### Requirement: Config is the source for re-runs
On re-run, groma SHALL read `.groma/config.yaml` and SHALL NOT ask questions already answered there, unless the user requests reconfiguration.

#### Scenario: Reconfigure skills only
- **WHEN** the user runs `/groma` and asks to change skills
- **THEN** only the skill selection is asked again, and other settings are kept

### Requirement: Schema versioning
groma SHALL refuse to silently reinterpret a config with a different `schema` value. For an older schema it SHALL print the migration steps. For a newer schema it SHALL ask the user to update the suite.

#### Scenario: Config from newer suite
- **WHEN** the config has `schema: 3` and the installed suite supports up to `schema: 2`
- **THEN** groma stops and prints the update command for the suite

### Requirement: Hand-editable config
The config SHALL be valid, commented YAML that users can edit by hand. groma SHALL validate it and report errors with line numbers.

#### Scenario: Unknown skill id
- **WHEN** `skills.design` lists `impecable` (typo)
- **THEN** groma reports the line, the unknown id and the closest catalog match `impeccable`

### Requirement: Living-docs settings
The `docs` section of `.groma/config.yaml` SHALL accept `gate` (`off`, `remind`, `review`, `strict`; default `review`) and `adr_from` (`design-alternatives`, `marked`, `off`; default `design-alternatives`). The config validator SHALL reject other values with the line number and the closest valid value.

#### Scenario: Typo in gate
- **WHEN** the config contains `gate: strikt`
- **THEN** validation fails with the line number and "did you mean strict?"

### Requirement: Repository reminder toggles
The config validator SHALL accept `reminders.uncommitted` and `reminders.unpushed` with the values `true` and `false`, and SHALL report other values as errors with the line number.

#### Scenario: Invalid toggle
- **WHEN** the config contains `unpushed: sometimes`
- **THEN** validation fails with the line number and "must be true or false"

### Requirement: Git settings validation
The config validator SHALL accept the `git` keys `integrate`, `branch_per_change`, `commits` and `push` with their allowed values, and SHALL reject other values with the line number and the closest valid value.

#### Scenario: Typo in strategy
- **WHEN** the config contains `integrate: rebsae`
- **THEN** validation fails with the line number and "did you mean rebase?"

### Requirement: Next-action settings
The `next` section of `.groma/config.yaml` SHALL accept `hook` (`on`, `off`; default `off` until the user agrees) and `reshow_minutes` (integer ≥ 0; 0 shows only on change). The validator SHALL reject other values with the line number.

#### Scenario: Negative reshow
- **WHEN** the config contains `reshow_minutes: -5`
- **THEN** validation fails with the line number

