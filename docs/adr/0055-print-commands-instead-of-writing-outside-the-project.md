---
status: proposed
date: 2026-11-13
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-agents/SKILL.md, tests/scripts/next-session.bats]
origin: c014-plugin-next-hooks#D4
---

# Print the flag command instead of writing outside the project

## Context and Problem Statement

The global switch of the next action is a file in the user's home folder (ADR 0053). groma writes only inside the project (ADR 0006). Who creates the flag file when the user says yes to the next action?

## Decision Drivers

* groma's write scope stays the project
* The user must not be left guessing what to do

## Considered Options

* Print `touch ~/.claude/.groma-next-always` (and `rm` to switch off) with the reason
* Create the flag file after a yes

## Decision Outcome

Chosen option: "print the command with the reason", because one pasted command is a small price for a write scope that never reaches `~`.

Details:
- groma-agents step 5 prints the `touch` and `rm` commands and says why: groma deliberately neither looks nor writes outside the project, so it cannot tell whether the flag exists and does not create it. The text goes into the findings report and the summary, in the user's language.
- The hook scripts only test whether the file exists.
- The same rule covers the status-line pill (ADR 0044, ADR 0056): a snippet, never an edit.

### Consequences

* Good, because no run of groma changes a file outside the project.
* Bad, because the user has to run one command by hand.
* Neutral, because groma cannot report whether the next action is on globally.

### Confirmation

`tests/scripts/next-session.bats` asserts that the hooks neither create nor remove the flag file or its folder. groma-agents step 5 forbids the write.

## Pros and Cons of the Options

### Create the flag file after a yes

* Bad, because groma's write scope would grow to `~`, against ADR 0006.

## More Information

From design decision D4 of c014-plugin-next-hooks. Related: ADR 0006, ADR 0044, ADR 0053.
