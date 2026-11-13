## Context

Skill descriptions and AGENTS.md are always loaded; everything else is loaded on demand. C010 provides per-fixture token numbers.

## Goals / Non-Goals

**Goals:**
- Fewer always-loaded tokens with unchanged eval results.

**Non-Goals:**
- Shortening SKILL.md bodies or references (loaded on demand).

## Decisions

### D1: Budgets enforced by the structure check
Each description at most 400 characters, all descriptions together at most 2000 characters; the AGENTS.md template at most 80 lines and 3200 characters. The 400 and 80 alone did not bind: eight descriptions could reach 3200 characters, and the template had 54 lines before the diet. The totals were therefore adjusted to the measured text: descriptions 2384 characters before the diet and 1821 after (1817 after review), template 3246 characters before and 2966 after (3013 after review restored one sentence). Both caps sit below the pre-diet text, so the diet cannot grow back unnoticed, with some headroom for wording changes.

Alternatives: trim once without a check (rejected: the text grows back); a token-count check with a tokenizer dependency (rejected: characters and lines are a good enough proxy without a new dependency).

### D2: Evals as the regression run
A trimmed description must still make the agent pick the skill. The evals confirm the skills still work end to end; triggering is not covered by a test.

## Risks / Trade-offs

- [A description too short stops triggering] → no test covers triggering; keep the trigger phrases (the "Use when" part) and restore a trigger word when a session misses a skill.
