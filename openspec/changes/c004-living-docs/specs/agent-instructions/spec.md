## ADDED Requirements

### Requirement: Living-docs instruction
The generated AGENTS.md SHALL tell agents to update the docs a change affects and to record design decisions with alternatives as ADRs in the same change, and SHALL name the docs impact command.

#### Scenario: Generated AGENTS.md
- **WHEN** groma writes AGENTS.md for a project with `docs.gate: review`
- **THEN** it contains the living-docs line with the `docs-impact.sh` command
