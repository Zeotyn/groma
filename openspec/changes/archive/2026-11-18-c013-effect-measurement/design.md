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

Chosen: `go-no-db` with the task "add a `-l` flag that counts lines" (`tests/evals/effect/go-no-db.md`); the acceptance test (`go-no-db.sh`, never shown to the agent) checks both counts, gofmt and no new dependency. The only conventions this fixture holds are gofmt and stdlib only, both visible in the code, so the first measurement is a floor: it shows what groma's added context costs on a small project with little to know. A fixture whose docs state a real decision is the follow-up if this signal calls for it; changing `go-no-db` itself would shift the `/groma` eval baseline.

Alternatives: one run per side (rejected: variance hides the effect); many fixtures (rejected: cost; start with one and extend if the signal is clear).

### D2: Pass rate counts with tokens
A cheaper run that fails the acceptance test is not a saving; the report shows both.

## Risks / Trade-offs

- [The task favors groma by construction] → choose a task whose needed knowledge exists in the code too, so the without-side can succeed.
- [Cost] → the run states its maximum cost before it starts, and checks everything that can stop it (claude CLI, skill source, the fixture's commands) before the first API call.
- [Both sides load the operator's user-level Claude Code settings, CLAUDE.md and skills] → accepted as a stated limit: pointing `CLAUDE_CONFIG_DIR` at an empty folder could break the login, which may live there, so the eval leaves it alone. Both sides see the same user-level context, which adds to both and may blur the difference; the script header and every report header name the limit.
- [A budget stop or permission denials skew a side] → every run row records the result subtype (`error_max_budget_usd` for a budget stop), the number of permission denials and the model id; the output names both per run.
