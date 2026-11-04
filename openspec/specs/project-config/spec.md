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

