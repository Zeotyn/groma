## ADDED Requirements

### Requirement: Style tools question
The interview SHALL ask for style tools only when detection found none. The recommended option SHALL be the table's default tools for the stack. In brownfield projects the recommended option SHALL be "document only", so that adding tools to existing code stays an explicit choice.

#### Scenario: Greenfield Python
- **WHEN** the project is greenfield and the user chose Python
- **THEN** the interview asks "Set up Ruff for formatting and linting? (recommended)"

#### Scenario: Brownfield with tools
- **WHEN** detection found `.prettierrc`
- **THEN** the interview asks no style tools question
