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

Chosen option: "Budgets in characters and lines", because it stops the text from growing back and needs no tokenizer. Each skill description has at most 400 characters and all descriptions together at most 2000; the AGENTS.md template has at most 80 lines and 3200 characters. The totals sit below the pre-diet text (descriptions 2384 characters, template 3246) and leave some room above the post-diet text (1821, later 1817; template 2966, later 3013), so the diet cannot silently be undone, while a ninth skill or a longer template needs trimming elsewhere or a new decision.

### Consequences

* Good, because a growing description or template fails `scripts/test.sh` with the skill and its length.
* Bad, because characters and lines only approximate tokens.
* Neutral, because the per-description cap alone would allow 3200 characters for eight skills; the total cap is what binds.
* Neutral, because the token report (C010) records the token effect; the numbers change only by a new decision.

### Confirmation

`tests/structure/check.py` (`check_skills`) and its unit tests enforce the caps; the evals confirm the skills still work end to end; triggering is not covered by a test.

## Pros and Cons of the Options

### Trim once without a check

* Good, because nothing new to maintain.
* Bad, because the text grows back unnoticed.

### Token-count check with a tokenizer

* Good, because it measures what costs.
* Bad, because it adds a dependency, and tokenizers differ between agents.

## More Information

From design decision D1 of c011-always-loaded-diet. Replaces the 150-line AGENTS.md budget that ADR 0031 mentions.
