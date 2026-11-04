---
name: groma-loop
description: Runs one change through propose, apply, verify and archive with an independent reviewer model - review rounds, mandatory answers to every finding, tests before review, autonomous or gated. Use for "groma-loop", "build this with review", "implement with a second model", or to review a proposal or implementation with another model.
---

# groma-loop

You are the **author** and the orchestrator. A different model is the **reviewer**. Every round: the reviewer finds, you answer each finding, the loop decides. The user is interrupted only on escalation (and, in `gated` mode, at the two gates).

Paths are relative to this skill folder unless they start with `<project>`. Settings come from `review` in `<project>/.groma/config.yaml`; missing keys use these defaults: `mode: autonomous`, `stop_when: no-high`, propose `reviewer: auto, max_rounds: 2`, apply `reviewer: auto, per: task-group, max_rounds: 1, test_retries: 2`.

## Start

1. **Change.** The user names an existing change or describes an idea. Existing change: start at the first phase whose work is missing (no tasks ticked → apply; all ticked → verify). New idea: start at propose.
2. **Methodology.** Read the matching section of [references/methodology-adapters.md](references/methodology-adapters.md).
3. **Reviewer.** For each phase you will run, resolve the reviewer once:
   ```sh
   sh scripts/resolve-reviewer.sh <your agent> --phase <propose|apply> --config <project>/.groma/config.yaml --author-model <your model>
   ```
   Say the result in one line, e.g. "Reviewer: gemini (other vendor)". `reviewer=self` means self-review: run each review as a fresh subagent or session that gets only the prompt file, and mark it `self-review` everywhere.
4. **Tests.** Find the project's test command (AGENTS.md, `package.json`, `Makefile`, CI workflow). No test command: say so once; the apply gate then only checks that the build or lint step passes, if any.

## Phases

Announce each step as `<Phase> · <unit> · round N of M`.

**Propose.** Write the change artifacts with the methodology's propose workflow. Then review rounds (below) on the artifacts. `gated`: after the loop, show a five-line summary (goal, scope, open rejected findings) and wait for approval.

**Apply.** Split the tasks into review units by `per` (task, task-group, change). For each unit:
1. Record the base: `git rev-parse HEAD` (or note "working tree" when uncommitted work exists).
2. Implement the unit's tasks, tick them.
3. **Tests gate.** Run the tests. Red: fix and rerun, at most `test_retries` times; still red → escalate with the failing output. No review on red tests.
4. Review rounds on the unit's diff (`git diff <base>`), its tasks and the requirements they implement.

**Verify.** Run the methodology's verify step, then one review round on its report and the full diff. Critical verify issues count as high findings.

**Archive.** `gated`: wait for approval. Then archive with spec sync. After archiving, run `sh ../groma-methodology/scripts/roadmap.sh --root <project>` when groma-methodology is installed.

## Review round

1. **Prompt.** Build `<change>/reviews/.prompt-<phase>-<n>.md` from [references/review-prompt.md](references/review-prompt.md): the phase's artifacts or diff, the project rules, and all earlier findings with your responses.
2. **Run.** `sh scripts/review.sh <reviewer> <prompt-file> <change>/reviews/.raw-<phase>-<n>.md` (or the fresh-context self-review). Exit 5: the reviewer failed; resolve again without it and record why.
3. **Answer every finding.** For each row: either fix it and write `fixed: <what changed>`, or write `rejected: <reason>`. A rejected finding is not argued again unless the reviewer brings new evidence.
4. **Record.** Write `<change>/reviews/<phase>-round-<n>.md` from [templates/review-record.md](templates/review-record.md) with all findings and responses. Delete the `.prompt-*` and `.raw-*` files.
5. **Decide.**
   - stop criterion holds (`no-high`: no open high finding; `no-findings`: no open finding; rejected counts as closed) → `stop-clean`, next phase.
   - round limit reached with open high findings → `escalate`.
   - you rejected a **high** finding → `escalate` (a human decides disagreements on high findings).
   - otherwise → next round with the fixes.

Done when the record exists and its `decision` is set.

## Escalation

Stop the loop, keep all work and records, and send one message:

```
groma-loop stopped: <cause, one line>
<the open findings or the failing test output, at most 10 lines>

Options:
1. <apply the reviewer's suggestion>
2. <accept the risk and continue>
3. <change the design / split the change>
```

Escalate also before any destructive step outside the change: deleting files that existed before the change, rewriting git history, force-pushing.

## Summary

At the end print: phases run, rounds per phase, reviewer per phase (with `self-review` marked), findings fixed and rejected (list every rejected one with its reason), test result, archive location, and the next action.
