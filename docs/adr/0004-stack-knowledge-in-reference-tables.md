---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-detect/references/signals.md, skills/groma-survey/references/data-sources.md, skills/groma-survey/references/adr-sources.md, openspec/changes/c001-groma-suite/design.md]
---

# Keep stack knowledge in reference tables, not code

## Context and Problem Statement

groma must work for any language or stack. Per-language extractors cannot cover "all stacks" and need a test matrix per language.

## Considered Options

* Markdown reference tables the agent applies
* Per-language extractor scripts

## Decision Outcome

Chosen option: "Markdown reference tables the agent applies", because the agent already reads every language; a new stack is a new table row.

### Consequences

* Good, because contributions are small and need no new tests.
* Bad, because results depend on how well the agent applies the table.

### Confirmation

AGENTS.md rule: stack-specific knowledge goes into `references/*.md`, never into skill logic. Evals on five fixtures with different stacks.

## More Information

Derived by groma from existing code on 2026-11-04 (design decision D2); confirm or reject.
