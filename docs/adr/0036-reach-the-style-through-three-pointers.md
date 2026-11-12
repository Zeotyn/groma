---
status: accepted
date: 2026-11-11
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-agents/templates/AGENTS.md, skills/groma-methodology/methodologies.yaml, skills/groma-loop/SKILL.md, skills/groma-loop/references/review-prompt.md]
origin: c005-code-style#D6
---

# Reach the style through three pointers

## Context and Problem Statement

A code-style doc helps only when agents read it before writing code and run its checks afterwards. Agents during a change see what AGENTS.md and the methodology context point them to, and groma-loop decides what gates a review. How does the style reach every change?

## Considered Options

* Three pointers: AGENTS.md gets a "Code style" section with the check commands; the methodology context gets one line when groma creates the config; groma-loop runs the check commands in the tests gate and includes the doc in the review prompt as project rules (tool rule: high, convention: medium)
* Install a stack-specific style skill from the catalog
* A pre-commit hook

## Decision Outcome

Chosen option: "three pointers", because outside the loop the first two carry the style to any agent, and inside the loop the gate enforces it. A catalog skill is deferred: it can be added later as rows, the doc stays the source. A pre-commit hook edits `.git/hooks` or needs a framework, which is outside groma's write scope.

### Consequences

* Good, because no new mechanism is needed; each pointer uses an existing file or step.
* Bad, because outside groma-loop nothing enforces the checks; the pointers are reminders.

### Confirmation

`tests/evals/assert.sh` checks that AGENTS.md lists the check commands and that `openspec/config.yaml` carries the code-style line; the loop eval runs the tests gate.

## More Information

From design decision D6 of c005-code-style. Related: ADR 0031, ADR 0009.
