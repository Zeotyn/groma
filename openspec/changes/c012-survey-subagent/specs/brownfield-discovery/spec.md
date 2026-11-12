## ADDED Requirements

### Requirement: Isolated, map-first survey
When the agent supports subagents, the survey SHALL run in one and SHALL hand back only the findings report path and a short summary. The survey SHALL build or read the code map first and read files targeted from it.

#### Scenario: Survey in a subagent
- **WHEN** `/groma` surveys a brownfield project in Claude Code
- **THEN** the main session receives the findings report path and at most ten summary lines, and the report has the same sections as an inline survey
