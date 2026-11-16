# lifecycle-reminders Specification

## Purpose
Keeps unfinished lifecycle work visible: changes ready to verify or archive, stale changes, and tasks ticked without tests, so nothing silently stays half done.
## Requirements
### Requirement: Status report
groma SHALL provide a read-only status script that lists, per active change: task progress, and at most one reminder with a concrete next action, in this priority: all tasks done → verify and archive; tasks ticked since the last commit that changed a test file → add or run tests; no commit touching the change folder for `stale_change_days` (default 14) → continue or close. Spike (`s`, `m<N>-spike-`) and refactor (`r`) changes, and old milestone (`m` with three digits) and docs (`d`) changes from the baseline, SHALL NOT get the test reminder. Files of the methodology (for example OpenSpec `spec.md`) SHALL NOT count as test files. A milestone section in `docs/roadmap.md` with open release-gate items SHALL get the line `M<N>  gate: <first open item>` when milestone N has at least one change, active or archived (a name `m<N>-…`, or for old names a `Milestone: mNNN` line), and none of them is active; a planned milestone without any change SHALL get no line. Nested checklist items SHALL count like top-level ones. For old umbrella milestone changes from the baseline the script SHALL keep the reminder `gate: <first open task>` when no active change references them through a `Milestone: mNNN` line. After the change lines the script SHALL report uncommitted files in the working tree and local commits on the main branch that its upstream does not have, using only local git state. The script SHALL print that nothing is open only when it printed no other line.

#### Scenario: Ready to archive
- **WHEN** `c001-groma-suite` has all tasks ticked
- **THEN** the report shows `c001-groma-suite 49/49 tasks → verify, then archive`

#### Scenario: Milestone without test reminder
- **WHEN** spike `m3-spike-plugin-hooks` has ticked tasks and no test file changed since
- **THEN** the report shows no test reminder for `m3-spike-plugin-hooks`

#### Scenario: Stale change
- **WHEN** the last commit touching `openspec/changes/c004-export/` is 34 days old and the change has open tasks
- **THEN** the report shows `c004-export  1/3 tasks → no commit for 34 days, continue or close`

#### Scenario: Milestone waiting for its release gate
- **WHEN** `docs/roadmap.md` has `## M2: v0.2` with release-gate item "Test levels 1–4 green" open, `m2-checkout` is archived and no active change starts with `m2-`
- **THEN** the report shows `M2  gate: Test levels 1–4 green`

#### Scenario: Planned milestone without changes
- **WHEN** `## M2: Planned` has open release-gate items and no change, active or archived, belongs to milestone 2
- **THEN** the report shows no gate line for M2, and the next action is not a milestone gate

#### Scenario: Milestone with active children
- **WHEN** `## M3` has open release-gate items and `m3-code-style` is active
- **THEN** the report shows no gate reminder for M3

#### Scenario: Unpushed commits
- **WHEN** `main` has 30 commits that `origin/main` does not have
- **THEN** the report contains `main: 30 commits not pushed → git push`

#### Scenario: Uncommitted files
- **WHEN** `git status --porcelain` lists 4 entries
- **THEN** the report contains `working tree: 4 files uncommitted → commit or stash`

#### Scenario: Nothing open
- **WHEN** no active change, ADR or repository state needs attention
- **THEN** the report prints a single line saying so

### Requirement: Surfacing to agents
AGENTS.md written by groma SHALL tell agents to run the status script at session start and to mention open reminders before starting new work. For Claude Code, groma SHALL offer an optional SessionStart hook that runs the script; it SHALL only be installed after the user agrees, and only into a settings file that groma creates or the user approves.

#### Scenario: Hook declined
- **WHEN** the user declines the hook
- **THEN** no settings file is changed, and the AGENTS.md line remains the reminder mechanism

### Requirement: Reminder configuration
The `reminders` section of `.groma/config.yaml` SHALL enable or disable each reminder (`archive_when_done`, `stale_change_days`, `untested_tasks`, `uncommitted`, `unpushed`).

#### Scenario: Stale reminder disabled
- **WHEN** `stale_change_days` is `0`
- **THEN** no stale reminders are shown

#### Scenario: Unpushed reminder disabled
- **WHEN** `unpushed` is `false` and `main` has local commits
- **THEN** no unpushed reminder is shown

### Requirement: Docs reminders
When `docs.gate` is not `off`, the status script SHALL remind for an active change whose tasks are all done and whose docs impact report is not empty ("update docs/<file> or add a Docs: task line"), and for an ADR with `status: proposed` whose `origin` change is archived ("accept or reject ADR NNNN"). The docs reminder SHALL take priority over the verify-and-archive reminder.

#### Scenario: Done but docs open
- **WHEN** all tasks of `c007-cache` are ticked and the report lists `docs/architecture.md`
- **THEN** the status line for `c007-cache` reads `… → update docs/architecture.md or add a Docs: task line`

#### Scenario: Pending ADR after archive
- **WHEN** `c007-cache` is archived and `docs/adr/0011-use-redis.md` still has `status: proposed`
- **THEN** the status output contains `ADR 0011 still proposed (c007-cache archived) → accept or reject`

