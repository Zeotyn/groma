## Purpose

Keeps unfinished lifecycle work visible: changes ready to verify or archive, stale changes, and tasks ticked without tests, so nothing silently stays half done.

## ADDED Requirements

### Requirement: Status report
groma SHALL provide a read-only status script that lists, per active change: task progress, and at most one reminder with a concrete next action. Reminders: all tasks done → verify and archive; no commit touching the change or its code for `stale_change_days` (default 14) → continue or close; tasks ticked since the last test-file change → add or run tests.

#### Scenario: Ready to archive
- **WHEN** `c001-groma-suite` has all tasks ticked
- **THEN** the report shows `c001-groma-suite 49/49 tasks → verify, then archive`

#### Scenario: Nothing open
- **WHEN** no active change needs attention
- **THEN** the report prints a single line saying so

### Requirement: Surfacing to agents
AGENTS.md written by groma SHALL tell agents to run the status script at session start and to mention open reminders before starting new work. For Claude Code, groma SHALL offer an optional SessionStart hook that runs the script; it SHALL only be installed after the user agrees, and only into a settings file that groma creates or the user approves.

#### Scenario: Hook declined
- **WHEN** the user declines the hook
- **THEN** no settings file is changed, and the AGENTS.md line remains the reminder mechanism

### Requirement: Reminder configuration
The `reminders` section of `.groma/config.yaml` SHALL enable or disable each reminder (`archive_when_done`, `stale_change_days`, `untested_tasks`).

#### Scenario: Stale reminder disabled
- **WHEN** `stale_change_days` is `0`
- **THEN** no stale reminders are shown
