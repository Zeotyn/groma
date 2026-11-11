---
name: groma-loop
description: Runs one change through propose, apply, verify and archive with an independent reviewer model - review rounds, mandatory answers to every finding, tests and style checks before review, autonomous or gated. Use for "groma-loop", "build this with review", "implement with a second model", or to review a proposal or implementation with another model.
---

# groma-loop

You are the **author** and the orchestrator. A different model is the **reviewer**. Every round: the reviewer finds, you answer each finding, the loop decides. The user is interrupted only on escalation (and, in `gated` mode, at the two gates).

Paths are relative to this skill folder unless they start with `<project>`. Settings come from `review` in `<project>/.groma/config.yaml`; missing keys use these defaults: `mode: autonomous`, `stop_when: no-high`, propose `reviewer: auto, max_rounds: 2`, apply `reviewer: auto, per: task-group, max_rounds: 1, test_retries: 2`. The docs gate reads `docs.gate` (default `review`).

## Start

1. **Change.** The user names an existing change or describes an idea. Existing change: start at the first phase whose work is missing (no tasks ticked → apply; all ticked → verify). New idea: start at propose.
2. **Methodology.** Read the matching section of [references/methodology-adapters.md](references/methodology-adapters.md).
3. **Reviewer.** For each phase you will run, resolve the reviewer once:
   ```sh
   sh scripts/resolve-reviewer.sh <your agent> --phase <propose|apply> --config <project>/.groma/config.yaml --author-model <your model>
   ```
   Say the result in one line, e.g. "Reviewer: gemini (other vendor)". `reviewer=self` means self-review: run each review as a fresh subagent or session that gets only the prompt file, and mark it `self-review` everywhere.
4. **Tests and style checks.** Find the project's test command (AGENTS.md, `package.json`, `Makefile`, CI workflow). No test command: say so once; the apply gate then only checks that the build or lint step passes, if any. Then read the "Enforced by tools" table of the code-style doc (`<project>/docs/code-style.md`, or the file the docs index lists for code style); its check commands run in every tests gate.

## Phases

Announce each step as `<Phase> · <unit> · round N of M`.

**Propose.** Write the change artifacts with the methodology's propose workflow. Then review rounds (below) on the artifacts. `gated`: after the loop, show a five-line summary (goal, scope, open rejected findings) and wait for approval.

**Apply.** Split the tasks into review units by `per` (task, task-group, change). For each unit:
1. Record the base: `git rev-parse HEAD` (or note "working tree" when uncommitted work exists).
2. Implement the unit's tasks, tick them.
3. **Tests gate.** Run the tests, then every check command from the code-style doc. A failing check counts as red tests. Red: fix and rerun, at most `test_retries` times; still red → escalate with the failing output (test or check). No review on red tests.
4. Review rounds on the unit's diff (`git diff <base>`), its tasks and the requirements they implement.

**Verify.** Run the methodology's verify step, then one review round on its report and the full diff. Critical verify issues count as high findings. **Docs gate** (`docs.gate` is `review` or `strict`, and groma-lay-out is installed): run `sh ../groma-lay-out/scripts/docs-impact.sh --root <project> <change-dir>` and add every `impact` and `adr` line as a high finding of that round. Answer an `impact` finding by updating the doc or by adding a task line `Docs: <path> unchanged, because <reason>`; answer an `adr` finding by writing the proposed ADR (groma-lay-out, "ADR candidates from a change").

**Archive.** `gated`: wait for approval. `strict`: run `docs-impact.sh --gate` first; exit 4 → escalate with the report instead of archiving (groma-lay-out missing: skip the check and say so). Before archiving, list the change's docs: `git diff --name-only <base> -- docs/` plus `git ls-files --others --exclude-standard -- docs/`, where `<base>` is the parent of the commit that added `<change-dir>/proposal.md` (`HEAD` when that commit does not exist). Then archive with spec sync, followed by the **docs sync** (skip it when `docs.gate` is `off`). These edits are authored work inside the user's change, like its code, not setup writes; they touch only the docs on that list:
1. Every ADR in `<project>/docs/adr/` with `origin: <change>#…` and `status: proposed` → `status: accepted`.
2. `last_reviewed` → today in every listed doc that has the key.
3. In `docs/adr/README.md`, set the status cell of each ADR accepted in step 1 to `accepted`, and add a row for every listed ADR still missing.
4. Run `sh ../groma-methodology/scripts/roadmap.sh --root <project>` when groma-methodology is installed.

## Review round

1. **Prompt.** Build `<change>/reviews/.prompt-<phase>-<n>.md` from [references/review-prompt.md](references/review-prompt.md): the phase's artifacts or diff, the project rules (AGENTS.md, accepted ADRs and the code-style doc), and all earlier findings with your responses.
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
