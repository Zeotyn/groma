## MODIFIED Requirements

### Requirement: Duplicate plugin detection
When the Claude Code plugin `groma` is installed, `groma init` SHALL still copy the skills for Claude by default, because the project copy is what the team gets, and SHALL print how to switch the plugin off for this project. When the user chooses to skip, no files are written to `.claude/skills/groma*` and the config records `agents_via_plugin: [claude]`.

#### Scenario: Plugin present, default
- **WHEN** `claude plugin list` shows `groma` and the user accepts the default
- **THEN** the Claude skill copies are written and the output says how to switch the plugin off for this project

#### Scenario: Plugin present
- **WHEN** `claude plugin list` shows `groma` and the user chooses skip
- **THEN** no files are written to `.claude/skills/groma*`, and the config records `agents_via_plugin: [claude]`
