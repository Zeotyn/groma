## MODIFIED Requirements

### Requirement: Status report
groma SHALL provide a read-only status script that lists, per active change: task progress, and at most one reminder with a concrete next action, in this priority: all tasks done → verify and archive; tasks ticked since the last commit that changed a test file → add or run tests; no commit touching the change folder for `stale_change_days` (default 14) → continue or close. Milestone (`m`) and docs (`d`) changes SHALL NOT get the test reminder, because they ship no code. Files of the methodology (for example OpenSpec `spec.md`) SHALL NOT count as test files. An active milestone with open tasks that no active change references through a `Milestone: mNNN` line SHALL get the reminder `gate: <first open task>` instead of the stale reminder. After the change lines the script SHALL report uncommitted files in the working tree and local commits on the main branch that its upstream does not have, using only local git state. The script SHALL print that nothing is open only when it printed no other line.

#### Scenario: Ready to archive
- **WHEN** `c001-groma-suite` has all tasks ticked
- **THEN** the report shows `c001-groma-suite 49/49 tasks → verify, then archive`

#### Scenario: Milestone without test reminder
- **WHEN** milestone `m001-mvp` has ticked tasks and no test file changed since
- **THEN** the report shows no test reminder for `m001-mvp`

#### Scenario: Stale change
- **WHEN** the last commit touching `openspec/changes/c004-export/` is 34 days old and the change has open tasks
- **THEN** the report shows `c004-export  1/3 tasks → no commit for 34 days, continue or close`

#### Scenario: Milestone waiting for its release gate
- **WHEN** `m002-v0-2` has tasks 1.1–1.3 ticked and 2.1 "Test levels 1–4 green" open, and no active change has `Milestone: m002`
- **THEN** the report shows `m002-v0-2  3/7 tasks → gate: 2.1 Test levels 1–4 green`

#### Scenario: Milestone with active children
- **WHEN** `m003-v0-3` has open tasks and `c005-code-style` is active with `Milestone: m003`
- **THEN** the report shows no gate reminder for `m003-v0-3`

#### Scenario: Unpushed commits
- **WHEN** `main` has 30 commits that `origin/main` does not have
- **THEN** the report contains `main: 30 commits not pushed → git push`

#### Scenario: Uncommitted files
- **WHEN** `git status --porcelain` lists 4 entries
- **THEN** the report contains `working tree: 4 files uncommitted → commit or stash`

#### Scenario: Nothing open
- **WHEN** no active change, ADR or repository state needs attention
- **THEN** the report prints a single line saying so

### Requirement: Reminder configuration
The `reminders` section of `.groma/config.yaml` SHALL enable or disable each reminder (`archive_when_done`, `stale_change_days`, `untested_tasks`, `uncommitted`, `unpushed`).

#### Scenario: Stale reminder disabled
- **WHEN** `stale_change_days` is `0`
- **THEN** no stale reminders are shown

#### Scenario: Unpushed reminder disabled
- **WHEN** `unpushed` is `false` and `main` has local commits
- **THEN** no unpushed reminder is shown
