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

## Implementation notes

- The hand-off lives in the findings report as a `## Hand-off` section of one to ten lines, and the subagent returns the report path plus exactly these lines. The eval cannot see a subagent's reply (`claude -p --output-format json` carries only the main session's final text), so "summary handed back within ten lines" is asserted on the report section the reply is copied from.
- `skills/groma-survey/scripts/report-check.sh` checks a report against the `## ` headings of `templates/findings.md` (a heading matches by its text before ` (`; every section; hand-off 1-10 lines in the first `## Hand-off`). A placeholder is only a `{{<name>}}` or `{{<name>: ...}}` whose name the template uses, outside fenced blocks and outside inline code spans that are not exactly one placeholder, so Helm, Jinja or Vue braces in evidence pass. The survey's report step is done when it exits 0; `tests/evals/assert.sh` uses it on the newest findings report marked `generated_by: groma-survey` (the template's frontmatter), and fails a brownfield fixture that has none. "Same sections as an inline survey" holds by construction: both fill the same template and pass the same check.
- D2's caps are a table in groma-survey's SKILL.md (code map 15, ADRs 50 frontmatter and title only, docs 30 frontmatter and headings only, migrations 20 newest first, code style 10 per top-level folder as before). Schema and ORM model files have no cap: they define the entities, and migrations serve only drift. The report's new `## Survey scope` table records files read per category; a hit cap is a finding, `medium` for the data model, else `low`. The highest ADR number comes from the file names and stands in the report's ADR summary row, so step 8 numbers correctly past the ADR cap.
- groma-survey itself carries the rule "Where you cannot ask" (subagent or headless): a question becomes a finding marked `unconfirmed` with the assumed default; the orchestrator only points to it and asks the user about those findings afterwards.
- graphify writes `graphify-out/` into its working directory, so the survey runs it from `<project>/.groma/`; an existing `<project>/graphify-out/` is read, not rebuilt. Assumption, not tested here: graphify skips the hidden `.groma/` folder when it scans the project.
- `tests/evals/run.sh` adds `Agent` to the allowed tools, otherwise the headless eval could only take the inline path and the token difference of task 2.3 would measure nothing.
- Baseline check of the assertions: the recorded 2026-11-13 run outputs (`/private/tmp/claude-502/baseline-evals/`) no longer existed when this was implemented, so the assertions were run against a report filled from the pre-change template, against one filled from the new template, against no report, and against the repository's own `docs/_groma/findings-2026-11-04.md`. The pre-change report fails both new assertions (missing `## Hand-off` and `## Survey scope`, hand-off 0 lines) and has every other section; that is the expected failure, because the old survey had neither section and handed back its summary only in chat. The new-template report passes both.
- Task 2.3 (eval run with the token difference) is open: eval run pending (cost). CHANGELOG is left to the integrator.
