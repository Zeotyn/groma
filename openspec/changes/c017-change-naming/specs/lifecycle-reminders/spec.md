## MODIFIED Requirements

### Requirement: Status report
groma SHALL provide a read-only status script that lists, per active change: task progress, and at most one reminder with a concrete next action, in this priority: all tasks done → verify and archive; tasks ticked since the last commit that changed a test file → add or run tests; no commit touching the change folder for `stale_change_days` (default 14) → continue or close. Spike (`s`, `m<N>-spike-`) and refactor (`r`) changes, and old milestone (`m` with three digits) and docs (`d`) changes from the baseline, SHALL NOT get the test reminder. Files of the methodology (for example OpenSpec `spec.md`) SHALL NOT count as test files. A milestone section in `docs/roadmap.md` with open release-gate items and no active `m<N>-` change SHALL get the line `M<N>  gate: <first open item>`; for old umbrella milestone changes from the baseline the script SHALL keep the reminder `gate: <first open task>` when no active change references them through a `Milestone: mNNN` line. After the change lines the script SHALL report uncommitted files in the working tree and local commits on the main branch that its upstream does not have, using only local git state. The script SHALL print that nothing is open only when it printed no other line.

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
- **WHEN** `docs/roadmap.md` has `## M2: v0.2` with release-gate item "Test levels 1–4 green" open, and no active change starts with `m2-`
- **THEN** the report shows `M2  gate: Test levels 1–4 green`

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
