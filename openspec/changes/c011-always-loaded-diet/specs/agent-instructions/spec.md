## ADDED Requirements

### Requirement: Always-loaded budget
The generated AGENTS.md SHALL stay within 80 lines, and every groma skill description SHALL stay within 400 characters. The structure check SHALL fail when either budget is exceeded.

#### Scenario: Description too long
- **WHEN** a SKILL.md `description` exceeds 400 characters
- **THEN** the structure check fails and names the skill and its length

#### Scenario: AGENTS.md template too long
- **WHEN** `skills/groma-agents/templates/AGENTS.md` exceeds 80 lines
- **THEN** the structure check fails and names the file and its line count

## MODIFIED Requirements

### Requirement: Canonical AGENTS.md
groma SHALL create `AGENTS.md` at the project root when absent. It SHALL contain build/test commands, conventions, the active methodology and skills, and a pointer to `docs/README.md`. It SHALL NOT duplicate architecture or directory listings.

#### Scenario: New AGENTS.md
- **WHEN** no AGENTS.md exists
- **THEN** groma creates one within 80 lines that references `docs/README.md`
