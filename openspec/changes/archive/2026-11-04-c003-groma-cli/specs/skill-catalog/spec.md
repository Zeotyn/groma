## ADDED Requirements

### Requirement: Shared install recipes
The per-agent install rules (Claude plugin command, `npx skills` agent ids, project skill folders, files each installer touches) SHALL live in data files read by both the CLI and the `groma-skills` skill, so both produce the same commands for the same config.

#### Scenario: Same commands from CLI and skill
- **WHEN** the CLI with `--print` and the skill both prepare installs for the same config
- **THEN** both write the same commands to `.groma/install.sh`
