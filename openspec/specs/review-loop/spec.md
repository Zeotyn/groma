# review-loop Specification

## Purpose
Runs a change through propose, apply, verify and archive with an author and an independent reviewer model, so mistakes one model cannot see get caught before they ship, with as little human interruption as the user chose.
## Requirements
### Requirement: Orchestrated lifecycle
`groma-loop` SHALL drive one change through the phases propose, apply, verify and archive by invoking the project's methodology workflows (for OpenSpec: propose, apply, verify, archive) and adding the review rounds between them. It SHALL announce each phase and round, e.g. "Propose · review round 2 of 2".

#### Scenario: Full run on OpenSpec
- **WHEN** the user runs groma-loop with an idea in an OpenSpec project
- **THEN** a change named by the convention is proposed, reviewed, applied with reviews per task group, verified and archived, and the user sees each phase announced

#### Scenario: Start from an existing change
- **WHEN** the user runs groma-loop for `c004-export-csv`, which has proposal and tasks but no implementation
- **THEN** the loop starts at apply

### Requirement: Reviewer resolution
With `reviewer: auto`, groma SHALL pick the reviewer in this order and record the choice: (1) an installed agent CLI from a different vendor than the author, (2) the author's agent with a different model, (3) a self-review in a fresh context, marked as `self-review` in the record. A pinned reviewer (`<agent>[:<model>]`) SHALL be used as configured; if it fails, groma SHALL fall back along the same order and record why.

#### Scenario: Other vendor available
- **WHEN** the author runs in Claude Code and the `gemini` CLI is installed and answers a probe prompt
- **THEN** the reviewer is `gemini`, and the review record names it

#### Scenario: No other CLI
- **WHEN** no other agent CLI works
- **THEN** the reviewer is the author's agent with a different model, or a marked self-review if no other model is available

### Requirement: Review rounds with mandatory responses
Each review round SHALL produce findings with severity (`high`, `medium`, `low`), location and suggestion. The author SHALL answer every finding with `fixed` (with what changed) or `rejected: <reason>`. Rejected findings SHALL NOT be re-raised in later rounds unless the reviewer adds new evidence.

#### Scenario: Finding rejected
- **WHEN** the reviewer flags a missing index and the author rejects it with a reason
- **THEN** the record shows the rejection, the next round does not repeat it, and the final summary lists it for the human

### Requirement: Stop criteria and round limits
A loop SHALL stop when the stop criterion holds (default `no-high`: no open high findings) or when `max_rounds` is reached (defaults: propose 2, apply 1 per task group). Reaching the limit with open high findings SHALL escalate.

#### Scenario: Clean after one round
- **WHEN** round 1 of the propose review returns only low findings
- **THEN** the loop ends after round 1 and continues with apply

### Requirement: Tests before review during apply
During apply, groma SHALL run the project's test command after each task group and start the review round only when tests pass. Failing tests SHALL go back to the author, at most `test_retries` times (default 2), then escalate.

#### Scenario: Red tests
- **WHEN** tests fail after a task group
- **THEN** no review round starts, the author fixes, and after two more failures the loop escalates with the failing output

### Requirement: Modes
`mode: autonomous` (default) SHALL run all phases without approval stops and escalate only on: open high findings at the round limit, tests still red after retries, a reviewer-author disagreement on a high finding, or a destructive step outside the change (deleting files that existed before the change, rewriting git history). `mode: gated` SHALL additionally stop for approval after propose and before archive.

#### Scenario: Autonomous archive
- **WHEN** verify passes in autonomous mode without open high findings
- **THEN** the change is archived without asking, and the summary lists the rejected findings for later review

#### Scenario: Gated stop
- **WHEN** mode is `gated` and the propose loop ends
- **THEN** groma shows the proposal summary and waits for approval before apply

### Requirement: Escalation
On escalation groma SHALL stop the loop, keep all work, and present one message with the cause, the open findings or failing output, and two or three concrete options.

#### Scenario: Stuck on a high finding
- **WHEN** round 2 still has an open high finding
- **THEN** groma stops and offers: apply the reviewer's suggestion, accept the risk and continue, or change the design

### Requirement: Review records
Every round SHALL be stored in the change folder as `reviews/<phase>-round-<n>.md` with reviewer, author, findings, responses and the stop decision, and SHALL be archived with the change.

#### Scenario: Records after archive
- **WHEN** a change with three review rounds is archived
- **THEN** its archive folder contains three review records

### Requirement: Configuration
The `review` section of `.groma/config.yaml` SHALL configure `mode`, per phase `reviewer`, `max_rounds` and (apply) `per` (`task`, `task-group`, `change`) and `test_retries`, and `stop_when`. `/groma` SHALL write the defaults; the config validator SHALL check them.

#### Scenario: Invalid reviewer
- **WHEN** `review.apply.reviewer` is `codx`
- **THEN** the validator reports the line and suggests `codex`

