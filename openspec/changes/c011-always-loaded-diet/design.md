## Context

Skill descriptions and AGENTS.md are always loaded; everything else is loaded on demand. C010 provides per-fixture token numbers.

## Goals / Non-Goals

**Goals:**
- Fewer always-loaded tokens with unchanged eval results.

**Non-Goals:**
- Shortening SKILL.md bodies or references (loaded on demand).

## Decisions

### D1: Budgets enforced by the structure check
Descriptions at most 400 characters; the AGENTS.md template at most 80 lines. The numbers are starting points; the change records the measured effect and adjusts them once.

Alternatives: trim once without a check (rejected: the text grows back); a token-count check with a tokenizer dependency (rejected: characters and lines are a good enough proxy without a new dependency).

### D2: Triggering verified by the evals
A trimmed description must still make the agent pick the skill; the full eval run is the proof.

## Risks / Trade-offs

- [A description too short stops triggering] → evals catch it; restore the trigger word.
