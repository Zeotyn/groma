## Context

`tests/evals/run.sh` called `claude -p --output-format text` and kept only the log. The JSON result of `claude -p --output-format json` carries `total_cost_usd`, `num_turns`, `duration_ms`, a top-level `usage` object and a `modelUsage` object with the tokens of every model the run used. Evals run on demand only (ADR 0008, amended by f006), so the report must come out of the runs that happen anyway.

## Goals / Non-Goals

**Goals:**
- One report row per fixture with tokens, cost, turns and duration; totals at the end of the output.
- A committed baseline and the difference per fixture against it.
- The report writer is tested without any model call.

**Non-Goals:**
- Scheduled eval runs (ADR 0008).
- Static per-skill cost from `claude plugin details` (ADR 0050); C011 owns the always-loaded diet.

## Decisions

### D1: A report script in `tests/evals/`, parsing JSON in awk
`tests/evals/token-report.sh` has four modes: `header`, `row <fixture> <result.json>`, `text <result.json>` and `summary <report.tsv> [<baseline.tsv>]`. A small awk walker keeps the key path while it reads the JSON, so only values at known paths count and token-like text inside the agent's answer never does. This follows the code-style rule that deterministic parsing is done in awk, not in a language runtime, and adds no `jq` dependency to CI.

### D2: Tokens summed over every model
`claude -p` may use more than one model in a run (a small model for auxiliary calls, subagents). The row sums `inputTokens`, `outputTokens`, `cacheReadInputTokens` and `cacheCreationInputTokens` over all entries of `modelUsage`, which matches `total_cost_usd`; without `modelUsage` it falls back to the top-level `usage`.

### D3: Dated reports ignored, baseline committed
`tests/evals/reports/<YYYY-MM-DDTHHMMSS>.tsv` (one per run) is git-ignored and uploaded by the evals workflow; `tests/evals/reports/baseline.tsv` is committed by hand after a full run. The totals' difference covers only fixtures present in both files, so a partial run compares like with like.

## Risks / Trade-offs

- [The JSON shape of `claude -p` changes] → a missing or unreadable result gives a row of `-` instead of failing the run; the samples in `tests/evals/samples/` document the expected shape.
- [Costs vary between runs of the same fixture] → the baseline is a single run; read small differences as noise.

## Implementation notes

- **No model call during the change.** The JSON samples in `tests/evals/samples/` are synthetic, written in the documented shape of the `claude -p` result (`type`, `subtype`, `total_cost_usd`, `usage`, `modelUsage`, ...); no recorded run was available and none was made, because each costs tokens. The first real run should confirm the shape (open question: whether `modelUsage` covers subagent tokens).
- **Log content.** stdout of `claude -p` now goes to `<work>/<fixture>.json`; `<fixture>.log` gets stderr followed by the agent's final text (`token-report.sh text`), so `assert.sh`, which greps the log for the final summary, reads the same text as with `--output-format text`.
- **`GROMA_EVAL_REPORTS`** overrides the report folder. `tests/scripts/token-report.bats` uses it to run `run.sh` with a stub `claude` on the `empty` fixture, so the wiring is tested without a model call.
- **Workflow.** The proposal says "nightly"; the evals workflow has run on demand only since f006 (ADR 0008 amendment). The upload step was added to that on-demand workflow, together with the per-fixture JSON results.
- **A cli fixture whose `groma init` fails** gets a row of `-`, so every requested fixture appears in the report.
- **One report per run** (review fix): the name carries the start time, so a partial run no longer overwrites the day's full report; the spec scenario names `<date>T<time>.tsv` instead of the proposal's `<date>.tsv`. The path is printed in the `== tokens, report: <path>` line right before the per-fixture lines, not after the totals, because the spec requires the output to end with the totals.
- **Rows without tokens or cost** (review fix): a result with `total_cost_usd` but neither `usage` nor `modelUsage` (or the reverse) gives a row of `-`, so an error result does not add zeros to totals and baseline differences; a missing `num_turns` or `duration_ms` alone gives `-` in that column. A baseline row of `-` shows `no baseline`; totals with no common fixture show `vs_baseline -`.
- **Log for runs without text** (review fix): when the result has no `result` text (error or budget stop), `token-report.sh text` writes `no result text: subtype=<s> is_error=<b>` to the log.
- **Upload pattern** `tests/evals/reports/[0-9]*.tsv`, so the committed baseline is not uploaded as a run report.
- **Baseline (task 2.3) not run.** It needs one full eval run, which costs money and is the maintainer's call: `scripts/test.sh evals`, then `cp <path from the run's "== tokens, report: <path>" line> tests/evals/reports/baseline.tsv` and a commit `test(c010-token-report): eval token baseline`. Eight fixtures at `GROMA_EVAL_BUDGET=3` cap the run at 24 USD.
- **CHANGELOG** is left to the integrator.
