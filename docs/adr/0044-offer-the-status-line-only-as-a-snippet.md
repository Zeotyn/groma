---
status: accepted
date: 2026-11-12
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-agents/SKILL.md, skills/groma-agents/templates/statusline-snippet.sh]
origin: c007-next-action#D4
---

# Offer the status line only as a snippet

## Context and Problem Statement

The Claude Code status line is the least noisy place for the next action. It is configured in user-owned files, often global ones (`~/.claude/settings.json`, `~/.claude/statusline.sh`).

## Decision Drivers

* groma writes only inside the project (ADR 0006)
* The status line is visible all the time without interrupting

## Considered Options

* Print a snippet: one line for an existing status line script, or a standalone script with its `statusLine` setting
* Write the status line config when none exists
* Skip the status line

## Decision Outcome

Chosen option: "Print a snippet", because it keeps groma's write scope inside the project and still makes the pill a copy-paste away.

### Consequences

* Good, because no user-owned file outside the project changes.
* Bad, because the user has to add the line by hand.

### Confirmation

groma-agents step 5 says never to edit a status line setting or script; the snippet goes into the findings report and the summary.

## Pros and Cons of the Options

### Write the config when none exists

* Bad, because global settings are outside the project, so groma's write scope would grow to `~`.

### Skip the status line

* Bad, because it is the least noisy display.

## More Information

From design decision D4 of c007-next-action. Related: ADR 0006.
