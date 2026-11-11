# agent-instructions Specification

## Purpose
Gives every supported coding agent the same project instructions from one canonical `AGENTS.md`, so Claude Code, Copilot, Gemini CLI, Cursor and Codex start from the same docs.
## Requirements
### Requirement: Canonical AGENTS.md
groma SHALL create `AGENTS.md` at the project root when absent. It SHALL contain build/test commands, conventions, the active methodology and skills, and a pointer to `docs/README.md`. It SHALL NOT duplicate architecture or directory listings.

#### Scenario: New AGENTS.md
- **WHEN** no AGENTS.md exists
- **THEN** groma creates one under 150 lines that references `docs/README.md`

### Requirement: Pointer files per configured agent
For each configured agent, groma SHALL create the agent's instruction file as a pointer to AGENTS.md when the file is absent: `CLAUDE.md` (`@AGENTS.md`), `GEMINI.md` (`@AGENTS.md`), `.github/copilot-instructions.md` (plain pointer), `.cursor/rules/groma.mdc` (`alwaysApply: true`). Codex reads AGENTS.md directly.

#### Scenario: Claude and Copilot configured
- **WHEN** agents are `[claude, copilot]` and neither file exists
- **THEN** `CLAUDE.md` and `.github/copilot-instructions.md` exist and point to AGENTS.md; no Gemini or Cursor files are created

### Requirement: Existing instruction files untouched
If an agent instruction file exists, groma SHALL NOT edit it and SHALL put a suggested pointer snippet in the findings report.

#### Scenario: Existing CLAUDE.md
- **WHEN** `CLAUDE.md` exists without a reference to AGENTS.md
- **THEN** the file is unchanged, and the findings report contains the line to add

### Requirement: Living-docs instruction
The generated AGENTS.md SHALL tell agents to update the docs a change affects and to record design decisions with alternatives as ADRs in the same change, and SHALL name the docs impact command.

#### Scenario: Generated AGENTS.md
- **WHEN** groma writes AGENTS.md for a project with `docs.gate: review`
- **THEN** it contains the living-docs line with the `docs-impact.sh` command

### Requirement: Code-style pointer
The generated AGENTS.md SHALL tell agents to read the code-style doc before writing code and to run its check commands after each task, and SHALL list those check commands. It SHALL NOT copy conventions from the doc.

#### Scenario: AGENTS.md with tools
- **WHEN** `docs/code-style.md` lists `npx prettier --check .` and `npm run lint`
- **THEN** AGENTS.md contains the pointer line and both commands

