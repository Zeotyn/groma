## ADDED Requirements

### Requirement: Next-action fallback and offer
The generated AGENTS.md SHALL tell agents to end a work session by naming the output of the next-action command. groma-agents SHALL offer, once, the Claude Code Stop hook and the status-line snippet when `claude` is among the agents.

#### Scenario: Offer declined
- **WHEN** the user declines both
- **THEN** no settings file changes, and AGENTS.md still contains the fallback line
