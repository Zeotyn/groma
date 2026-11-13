## MODIFIED Requirements

### Requirement: Next-action fallback and offer
The generated AGENTS.md SHALL tell agents to end a work session by naming the output of the next-action command. groma-agents SHALL offer, once, the next action when `claude` is among the agents: with the groma plugin installed, it SHALL print the global flag command and the status-line pill instead of writing settings; without the plugin, it SHALL offer the Claude Code Stop hook through the settings file and the status-line snippet.

#### Scenario: Offer declined
- **WHEN** the user declines both
- **THEN** no settings file changes, and AGENTS.md still contains the fallback line

#### Scenario: Plugin installed
- **WHEN** the groma plugin is installed and the user agrees
- **THEN** no settings file changes, and the summary shows `touch ~/.claude/.groma-next-always` with the reason and the pill line
