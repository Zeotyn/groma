---
status: proposed
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [cli/config.js, skills/groma/SKILL.md]
origin: c003-groma-cli#D6
---

# Share step state between the CLI and the /groma skill

## Context and Problem Statement

After `groma init`, the `/groma` orchestrator must not repeat the setup questions the CLI already answered.

## Considered Options

* The CLI writes `steps.config|methodology|skills` and `initialized_with`; the orchestrator resumes from `steps`

No alternatives were recorded.

## Decision Outcome

Chosen option: "Write step state from the CLI", because the orchestrator already resumes from `steps` (C001). The only orchestrator change is to skip the setup questions and to recommend the CLI for pending installs.

### Consequences

* Good, because both entry points continue from the same state.
* Bad, because CLI and orchestrator must agree on the `steps` schema.

### Confirmation

`cli/test/config.test.js` and the eval run for `groma init` followed by `/groma` under `tests/evals/`.

## More Information

From design decision D6 of c003-groma-cli. No alternatives were recorded.
