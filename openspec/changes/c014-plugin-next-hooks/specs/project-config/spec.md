## MODIFIED Requirements

### Requirement: Next-action settings
The `next` section of `.groma/config.yaml` SHALL accept `hook` (`on`, `off`, `auto`; unset means `auto`, and `auto` defers to the global flag file `~/.claude/.groma-next-always`) and `reshow_minutes` (integer ≥ 0; 0 shows only on change). The config template SHALL leave `hook` unset. The validator SHALL reject other values with the line number.

#### Scenario: Negative reshow
- **WHEN** the config contains `reshow_minutes: -5`
- **THEN** validation fails with the line number

#### Scenario: Auto hook
- **WHEN** the config contains `hook: auto`
- **THEN** validation passes and the hooks follow the global flag file
