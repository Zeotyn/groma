Milestone: m004

## Why

The brownfield survey is groma's most expensive step: the agent reads many files to map the code, find decisions and derive the data model, and all of it stays in the main session's context afterwards. A survey that runs in a subagent and starts from a code map leaves only the findings report in the main context.

## What Changes

- groma-survey runs in a subagent when the agent supports it, and returns only the path of the findings report and a short summary.
- The survey builds or reads the code map first (graphify when installed, else the file tree and manifests) and reads files targeted from it instead of broadly.
- Measured with the C010 report on the brownfield fixtures, before and after.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `brownfield-discovery`: the survey runs isolated and code-map first, and hands back only the report.

## Docs impact

`docs/architecture.md` (survey flow); ADR for running the survey in a subagent.

## Impact

`skills/groma-survey/SKILL.md`, `skills/groma/SKILL.md` (how the orchestrator invokes the survey). Agents without subagents keep the inline survey.
