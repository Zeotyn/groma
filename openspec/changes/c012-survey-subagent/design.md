## Context

The survey runs inline today. Claude Code and other agents can run a task in a separate context and return a result.

## Goals / Non-Goals

**Goals:**
- Less context in the main session after a survey, with the same findings.

**Non-Goals:**
- Changing what the survey finds.

## Decisions

### D1: Survey in a subagent where available, inline otherwise
The orchestrator starts the survey as a subagent with the project path; the subagent writes the findings report and returns its path and at most ten summary lines.

Alternatives: always inline (rejected: the main context carries every file read); a script-only survey (rejected: conventions and decisions need the agent's judgment).

### D2: Code map first
The survey reads the map, then targeted files per finding category, with a cap on files read per category recorded in the report.

## Risks / Trade-offs

- [Subagent misses context the interview needs] → the summary lines and the report path give the main session what it needs; evals check the interview still uses survey results.
