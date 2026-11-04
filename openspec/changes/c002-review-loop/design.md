## Context

See proposal.md. C001 delivers the methodology setup and the change convention; this change adds how changes are worked through. Agents differ in how they can call other models: Claude Code has subagents with a model parameter; every agent that can run shell commands can call another vendor's CLI headless (`gemini -p`, `copilot -p`, `codex exec`, `claude -p`; flags verified for gemini, copilot and claude on 2026-11-04; codex not installed locally, unverified).

## Goals / Non-Goals

**Goals:**
- Independent review with the least setup: works with zero extra logins (fallback), gets better with each installed CLI.
- Autonomous by default, with escalation that never loses work.
- Methodology-agnostic orchestration; OpenSpec first.

**Non-Goals:**
- Our own diff/patch tooling: the author edits files with its normal tools.
- Parallel multi-change orchestration. One change per loop.
- Replacing superpowers or OpenSpec workflows; groma-loop calls them.

## Decisions

### D1 Skill `groma-loop` owns the orchestration
A separate skill (not part of `groma`), because it runs repeatedly for every change while `groma` runs once per project. It reads `review` from the config and calls the methodology's workflows. Methodology adapters live in `references/methodology-adapters.md` (OpenSpec full; Spec Kit specify/plan/tasks/implement; others: propose = write proposal by convention, apply = work through tasks).

### D2 Reviewer invocation through `scripts/review.sh`
`review.sh <reviewer> <prompt-file> <output-file>` wraps the CLIs headless and read-only:

| Reviewer | Command |
|---|---|
| `claude[:model]` | `claude -p --model <m> --permission-mode plan` |
| `gemini[:model]` | `gemini -p ... [-m <m>]` |
| `copilot[:model]` | `copilot -p ... [--model <m>]` |
| `codex[:model]` | `codex exec ...` (unverified) |

The prompt file contains the review instructions, the change artifacts and the diff; the reviewer never gets write tools. `review.sh --probe <reviewer>` sends a one-line prompt to check installation and login. `scripts/resolve-reviewer.sh <author-agent>` applies the auto order and prints the chosen reviewer and the reason.
*Alternative:* subagents only, rejected because they stay within one vendor and are Claude-specific. Subagents remain step 2 of the order in Claude Code.

### D3 Structured findings
Reviewers answer in a fixed Markdown table (`| id | severity | location | finding | suggestion |`). `review.sh` validates the table; on a malformed answer it retries once with a format reminder, then records the raw answer and treats it as one medium finding "unparseable review".

### D4 Diff-scoped apply reviews
Apply reviews receive the task group's diff (`git diff` against the commit before the group, or the working tree diff) plus the change's specs, not the whole repository. Keeps cost per round predictable.

### D5 Status script in groma-methodology
`status.sh` lives in `groma-methodology/scripts/` because it reads the change folders and conventions, which that skill owns. It is read-only and fast (git and file reads only), so it can run on every session start.

### D6 Optional Claude hook
SessionStart hook in `.claude/settings.json` running `status.sh`. Only offered; written only when the file does not exist (additive) or after explicit approval for an existing file (same rule as D11 in C001).

## Risks / Trade-offs

- [Cost per change grows with rounds] → defaults 2/1, diff-only apply reviews, tests first.
- [Reviewer CLI asks for login interactively] → probe with a timeout; on failure fall back and record it.
- [Autonomous mode archives a change the user would have rejected] → archive is a git-tracked move; the summary lists every rejected finding; `gated` is one config line away.
- [Self-review fallback gives false confidence] → marked `self-review` in records and summary.
- [Infinite ping-pong] → mandatory responses, no re-raise of rejected findings without new evidence, hard round limit.

## Migration Plan

New keys with defaults; configs without `review` behave as `mode: autonomous`, `reviewer: auto`. The validator accepts configs without the section.

## Open Questions

- Exact Codex CLI headless flags (verify when a maintainer has Codex installed; marked best effort).
