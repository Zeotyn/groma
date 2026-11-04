---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-loop/scripts/review.sh, skills/groma-loop/scripts/resolve-reviewer.sh, tests/scripts/review.bats]
origin: c002-review-loop#D2
---

# Invoke reviewers through one headless, read-only wrapper script

## Context and Problem Statement

The review needs a second model. Agents differ in how they can call other models: Claude Code has subagents with a model parameter, and every agent that can run shell commands can call another vendor's CLI headless.

## Considered Options

* `scripts/review.sh <reviewer> <prompt-file> <output-file>` wrapping the CLIs headless and read-only
* Subagents only

## Decision Outcome

Chosen option: "`review.sh` wrapping the CLIs", because subagents stay within one vendor and are Claude-specific. The wrapper uses `claude -p --permission-mode plan`, `gemini -p`, `copilot -p` and `codex exec` (codex flags unverified). The prompt file holds the review instructions, the change artifacts and the diff, and the reviewer never gets write tools. `review.sh --probe <reviewer>` checks installation and login with a one-line prompt. `resolve-reviewer.sh <author-agent>` applies the auto order and prints the choice and the reason. Subagents remain step 2 of the order in Claude Code.

### Consequences

* Good, because it works with zero extra logins through the fallback and improves with each installed CLI.
* Bad, because the Codex flags are unverified and best effort.

### Confirmation

`tests/scripts/review.bats` tests the wrapper and the reviewer resolution.

## More Information

From design decision D2 of c002-review-loop. Related: ADR 0005.
