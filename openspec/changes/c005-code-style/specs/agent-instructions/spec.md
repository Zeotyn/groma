## ADDED Requirements

### Requirement: Code-style pointer
The generated AGENTS.md SHALL tell agents to read the code-style doc before writing code and to run its check commands after each task, and SHALL list those check commands. It SHALL NOT copy conventions from the doc.

#### Scenario: AGENTS.md with tools
- **WHEN** `docs/code-style.md` lists `npx prettier --check .` and `npm run lint`
- **THEN** AGENTS.md contains the pointer line and both commands
