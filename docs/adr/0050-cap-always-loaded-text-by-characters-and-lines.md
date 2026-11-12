---
status: proposed
date: 2026-11-12
decision-makers: Eugen Waldschmidt
evidence: [tests/structure/check.py, skills/groma-agents/templates/AGENTS.md]
origin: c011-always-loaded-diet#D1
---

# Cap always-loaded text by characters and lines

## Context and Problem Statement

The eight skill descriptions and the generated AGENTS.md sit in the agent's context on every turn of every session. Text there costs tokens all the time, and it tends to grow with each change. How do we keep it small?

## Decision Drivers

* Always-loaded text costs on every turn; on-demand text (skill bodies, references) does not
* No new dependency in the structure check
* A trimmed description must still trigger its skill

## Considered Options

* Budgets in characters and lines, enforced by the structure check
* Trim once without a check
* A token-count check with a tokenizer

## Decision Outcome

Chosen option: "Budgets in characters and lines", because it stops the text from growing back and needs no tokenizer. Descriptions have at most 400 characters, the AGENTS.md template at most 80 lines.

### Consequences

* Good, because a growing description or template fails `scripts/test.sh` with the skill and its length.
* Bad, because characters and lines only approximate tokens.
* Neutral, because the numbers are starting points; they are adjusted once the token report (C010) measures the effect.

### Confirmation

`tests/structure/check.py` (`check_skills`) and its unit tests; the evals confirm that trimmed descriptions still trigger.

## Pros and Cons of the Options

### Trim once without a check

* Good, because nothing new to maintain.
* Bad, because the text grows back unnoticed.

### Token-count check with a tokenizer

* Good, because it measures what costs.
* Bad, because it adds a dependency, and tokenizers differ between agents.

## More Information

From design decision D1 of c011-always-loaded-diet. Replaces the 150-line AGENTS.md budget that ADR 0031 mentions.
