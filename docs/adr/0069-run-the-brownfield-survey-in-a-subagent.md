---
status: proposed
date: 2026-11-16
decision-makers: Eugen Waldschmidt
evidence: [skills/groma/SKILL.md, skills/groma-survey/SKILL.md, skills/groma-survey/scripts/report-check.sh, skills/groma-survey/templates/findings.md, tests/evals/assert.sh]
origin: c012-survey-subagent#D1
---

# Run the brownfield survey in a subagent where the agent has one

## Context and Problem Statement

The brownfield survey is groma's most expensive step: the agent reads manifests, entry points, ADRs, docs, migrations and code samples. Run inline, every file it read stays in the main session's context for the rest of `/groma`, although the later steps need only the findings. How does the main session get the survey's results without carrying its reading?

## Decision Drivers

* Less context in the main session after a survey, with the same findings
* Conventions and decisions need the agent's judgment, not only scripts
* Agents without subagents must still run the survey
* The hand-back must be checkable without a model

## Considered Options

* A subagent where available, inline otherwise
* Always inline
* A script-only survey

## Decision Outcome

Chosen option: "a subagent where available, inline otherwise", because the survey's reading leaves the main context while the agent's judgment stays.

Details:
- `/groma` step 6 starts a subagent (in Claude Code the Agent tool) with the project path and the task to follow `groma-survey/SKILL.md` and reply with the report path and the filled report, without writing the report file: Claude Code refuses report files written by a subagent ("Subagents should return findings as text, not write report files"), which the first eval run hit on every brownfield fixture. The main session writes the reply's report to that path unchanged, at once, runs `report-check.sh` and fixes only what it names; later snippets go in with an edit, the report is never rewritten. It tells the user the Hand-off lines, asks about the survey's `unconfirmed` findings and reads report sections only as the docs step needs them. Agents without subagents follow the survey inline, as before, and write the report themselves.
- The findings report carries the hand-off itself: a "Hand-off" section of one to ten lines (counts per severity, top three findings, what the docs step needs), the part of the report the main session reads to go on, so the eval can check the length from the report.
- groma-survey never waits for an answer where it cannot ask (subagent or headless): each question, such as the schema dump offer, becomes a finding marked `unconfirmed`.
- The survey reads the code map first and opens files targeted from it, with a cap per category (code map, ADRs, docs, migrations, code style; schema and ORM model files are read in full); the report's "Survey scope" records files read against each cap, and a capped data model is a medium finding. graphify runs from `<project>/.groma/`, so its `graphify-out/` lands there.
- `scripts/report-check.sh` checks a report against the findings template: its `generated_by: groma-survey` frontmatter line, every section with content (an empty table says "None found."), no template placeholder (other braces in evidence do not count), a hand-off of one to ten lines. The survey's last step, or the main session's write of a subagent's report, is done when it exits 0; the brownfield evals assert the same.

### Consequences

* Good, because the main session carries the report instead of every file the survey read.
* Good, because an inline and an isolated survey write the same report from the same template.
* Bad, because the subagent cannot ask the user; questions it would ask (for example the schema dump offer) become `unconfirmed` findings that the main session asks afterwards.
* Bad, because the subagent rereads the skill and the config, which costs tokens in the subagent; the eval token report shows whether the total drops.
* Bad, because the report is generated twice, once in the subagent's reply and once in the main session's write, and the main context holds it; inline it is generated once.

### Confirmation

`tests/scripts/report-check.bats` checks the script; `tests/evals/assert.sh` asserts on the survey's report (`generated_by: groma-survey`) that it has every template section and a hand-off of one to ten lines, and fails a brownfield run without one. The confirmation is partial until an eval run records the token difference against `tests/evals/reports/baseline.tsv` in the change's tasks.

## Pros and Cons of the Options

### Always inline

* Good, because it needs nothing from the agent.
* Bad, because the main context carries every file read for the rest of the run.

### A script-only survey

* Good, because it costs no model tokens.
* Bad, because conventions, decisions and the data model need the agent's judgment (ADR 0034).

## More Information

Decision D1 of `openspec/changes/c012-survey-subagent/design.md`. Related: ADR 0034, ADR 0071.
