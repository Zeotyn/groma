## ADDED Requirements

### Requirement: Isolated, map-first survey
When the agent supports subagents, the survey SHALL run in one and SHALL hand back only the findings report path and the filled findings report, without writing the report file; the main session SHALL write that report unchanged and check it against the findings template. The survey SHALL build or read the code map first and read files targeted from it.

#### Scenario: Survey in a subagent
- **WHEN** `/groma` surveys a brownfield project in Claude Code
- **THEN** the main session receives the findings report path and the filled report, writes it unchanged, and the report has the same sections as an inline survey, the template's `generated_by: groma-survey` line and a Hand-off section of at most ten lines

#### Scenario: Report not following the template
- **WHEN** a findings report lacks the template's `generated_by` line or a template section, or a section has no content
- **THEN** `report-check.sh` names each missing line and empty section and exits 1
