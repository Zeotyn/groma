## Context

C010 gives per-run token numbers. Agent runs vary; one pair of runs proves little.

## Goals / Non-Goals

**Goals:**
- A repeatable comparison with a stated number of runs per side.

**Non-Goals:**
- A general benchmark across stacks.

## Decisions

### D1: One fixture, one task, at least three runs per side
The `go-no-db` or `node-prisma` fixture with one task that needs project knowledge (a decision or convention that only the docs state). Report median and spread.

Alternatives: one run per side (rejected: variance hides the effect); many fixtures (rejected: cost; start with one and extend if the signal is clear).

### D2: Pass rate counts with tokens
A cheaper run that fails the acceptance test is not a saving; the report shows both.

## Risks / Trade-offs

- [The task favors groma by construction] → choose a task whose needed knowledge exists in the code too, so the without-side can succeed.
- [Cost] → the run states its maximum cost before it starts.
