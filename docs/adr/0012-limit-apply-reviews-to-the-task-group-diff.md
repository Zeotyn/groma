---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-loop/references/review-prompt.md, skills/groma-loop/SKILL.md]
origin: c002-review-loop#D4
---

# Review apply work from the task group diff, not the whole repository

## Context and Problem Statement

Every review round costs tokens. Sending the whole repository would make the cost per round grow with project size.

## Considered Options

* Send the task group's diff plus the change's specs
* Send the whole repository

## Decision Outcome

Chosen option: "Send the task group's diff plus the change's specs", because it keeps the cost per round predictable. The diff is `git diff` against the commit before the group, or the working tree diff.

### Consequences

* Good, because cost per round does not depend on repository size.
* Bad, because the reviewer cannot see code outside the diff unless the prompt names it.

### Confirmation

Review of `skills/groma-loop/SKILL.md` and `review-prompt.md`. No automated test.

## More Information

From design decision D4 of c002-review-loop. The design names the whole repository only as what the review avoids. Related: ADR 0010.
