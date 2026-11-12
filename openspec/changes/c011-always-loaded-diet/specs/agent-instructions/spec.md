## ADDED Requirements

### Requirement: Always-loaded budget
The generated AGENTS.md SHALL stay within 80 lines, and every groma skill description SHALL stay within 400 characters. The structure check SHALL fail when either budget is exceeded.

#### Scenario: Description too long
- **WHEN** a SKILL.md `description` exceeds 400 characters
- **THEN** the structure check fails and names the skill and its length
