---
status: proposed
date: 2026-11-11
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-survey/SKILL.md, skills/groma-lay-out/templates/docs/code-style.md]
origin: c005-code-style#D4
---

# Infer conventions by the agent, bounded and cited

## Context and Problem Statement

Conventions such as naming, test placement, import style and error handling are the part of a code style that no tool enforces. Nothing in the repository states them. How does groma find them without language-specific code?

## Considered Options

* The agent samples up to 10 files per top-level source folder, preferring recently changed ones (`git log`), writes at most 12 conventions, each with a file path and a line where it shows a specific construct, tagged `EXTRACTED` (from configuration) or `INFERRED`; areas without a clear pattern get "No consistent pattern found."
* A script heuristic for naming and test placement
* No inference; document tools only

## Decision Outcome

Chosen option: "bounded, cited inference by the agent", because a script heuristic would need per-language rules (ADR 0004), while the agent already reads any language. The bounds (sample size, 12 lines, a path per line) keep the output small and checkable; the tags follow what the data model already does. No inference was rejected because conventions are exactly what tools do not capture.

### Consequences

* Good, because every convention is traceable to a file and a review of the first docs run can confirm or correct it.
* Bad, because inferred conventions can be wrong; the `INFERRED` tag makes the uncertainty visible.

### Confirmation

`tests/evals/assert.sh` checks on node-prisma that the Conventions section carries `INFERRED` or `EXTRACTED` tags.

## More Information

From design decision D4 of c005-code-style. Related: ADR 0031.
