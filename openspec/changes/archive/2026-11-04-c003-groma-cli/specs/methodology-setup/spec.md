## ADDED Requirements

### Requirement: Shared methodology recipes
Methodology init recipes SHALL live in one data file read by both the CLI and the `groma-methodology` skill. Each recipe SHALL declare: id, detection paths (already present), prerequisites, the init command with its agent-id mapping, the files it touches, whether it can run non-interactively, and the docs link step.

#### Scenario: New methodology version
- **WHEN** a contributor bumps the OpenSpec version in the recipe file
- **THEN** both `groma init` and the skill use the new version, with no other file changed
