## ADDED Requirements

### Requirement: Code style in methodology context
When groma creates the methodology's config, its project context SHALL include "Code style lives in docs/code-style.md or the code-style doc listed in docs/README.md; follow it and run its check commands." When the config already existed, the line SHALL go into the findings report as a snippet.

#### Scenario: Fresh OpenSpec setup
- **WHEN** groma creates `openspec/config.yaml`
- **THEN** its `context` contains the code-style line next to the docs line
