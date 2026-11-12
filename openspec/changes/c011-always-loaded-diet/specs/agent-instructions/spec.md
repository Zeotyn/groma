## ADDED Requirements

### Requirement: Always-loaded budget
The generated AGENTS.md SHALL stay within 80 lines. The structure check SHALL enforce the budget of its source, the template `skills/groma-agents/templates/AGENTS.md`: at most 80 lines and at most 3200 characters. Every groma skill description SHALL stay within 400 characters, and all groma skill descriptions together within 2000 characters. The structure check SHALL fail when any of these budgets is exceeded; the eval assertions SHALL fail when a generated AGENTS.md has more than 80 lines.

#### Scenario: Description too long
- **WHEN** a SKILL.md `description` exceeds 400 characters
- **THEN** the structure check fails and names the skill and its length

#### Scenario: Descriptions together too long
- **WHEN** all SKILL.md `description` fields together exceed 2000 characters
- **THEN** the structure check fails and names the total

#### Scenario: AGENTS.md template too long
- **WHEN** `skills/groma-agents/templates/AGENTS.md` exceeds 80 lines or 3200 characters
- **THEN** the structure check fails and names the file and its line or character count

#### Scenario: Generated AGENTS.md too long
- **WHEN** an eval fixture's generated AGENTS.md has more than 80 lines
- **THEN** the eval assertions fail

## MODIFIED Requirements

### Requirement: Canonical AGENTS.md
groma SHALL create `AGENTS.md` at the project root when absent. It SHALL contain build/test commands, conventions, the active methodology and skills, and a pointer to `docs/README.md`. It SHALL NOT duplicate architecture or directory listings.

#### Scenario: New AGENTS.md
- **WHEN** no AGENTS.md exists
- **THEN** groma creates one within 80 lines that references `docs/README.md`
