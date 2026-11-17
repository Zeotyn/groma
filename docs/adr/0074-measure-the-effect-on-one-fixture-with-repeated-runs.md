---
status: proposed
date: 2026-11-17
decision-makers: Eugen Waldschmidt
evidence: [tests/evals/effect.sh, tests/evals/effect/go-no-db.md, tests/evals/effect/go-no-db.sh, tests/scripts/effect.bats]
origin: c013-effect-measurement#D1
---

# Measure the effect on one fixture with repeated runs per side

## Context and Problem Statement

groma claims that its setup helps an agent work on a project. The token report of C010 gives per-run numbers, but agent runs vary, so one run with and one without groma's setup proves little. How do we measure the effect at a cost we can pay by hand?

## Decision Drivers

* Variance between runs must be visible, not hidden in a single pair
* Every paid run is started by hand, so the maximum cost must be known up front
* The task must be solvable without groma, so a pass rate can be compared at all

## Considered Options

* One fixture, one scripted task, at least three runs per side
* One run per side
* Many fixtures and tasks at once

## Decision Outcome

Chosen option: "One fixture, one scripted task, at least three runs per side", because it shows median and spread at a cost the operator states before the run. `tests/evals/effect.sh` runs the task in `tests/evals/effect/<fixture>.md` on fresh copies of the plain fixture and of the project after one `/groma` run, alternating sides and order, and checks each result with an acceptance test the agent never sees. The report has one row per run (tokens, cost, turns, duration, pass, result subtype, permission denials, model id) and per side the median, min and max with the pass rate. The first fixture is `go-no-db` with the task "add a `-l` flag"; its only conventions are visible in the code, so it measures a floor.

One run per side lost because variance hides the effect. Many fixtures lost on cost; a second fixture follows when the first signal calls for it.

### Consequences

* Good, because pass rate and cost are reported together: a cheaper run that fails is no saving.
* Good, because a run with denied tools or a budget stop is visible in its row.
* Bad, because three runs per side give a rough median only.
* Bad, because both sides load the operator's user-level Claude Code settings, CLAUDE.md and skills; the eval states this limit instead of replacing the config folder, where the login may live.

### Confirmation

`tests/scripts/effect.bats` runs the comparison loop against a stub `claude` and checks the summary, the checks before the first API call and that an interrupted run leaves no report.
