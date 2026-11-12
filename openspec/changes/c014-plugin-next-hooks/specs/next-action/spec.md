## ADDED Requirements

### Requirement: Hooks in the plugin
The groma Claude Code plugin SHALL register its next-action hooks through its own `hooks/hooks.json`: a `SessionStart` hook for startup, resume, clear and compact, and the debounced `Stop` hook. Both SHALL exit without output when the project has no `.groma/` folder or the next action is off. No settings file SHALL be written when the plugin is installed.

#### Scenario: Project without groma
- **WHEN** a session starts in a repository without `.groma/` and the plugin is enabled
- **THEN** both hooks print nothing and return within 50 ms

### Requirement: Next action at session start
When the next action is on, the `SessionStart` hook SHALL print the long next-action line so that it reaches the agent's context, once per session start, resume, clear or compaction.

#### Scenario: New session after a break
- **WHEN** a session starts in a groma project whose milestone waits for its release gate
- **THEN** the agent's context contains the next-action line naming that gate

### Requirement: On/off by project and global flag
The next-action hooks SHALL be on when `next.hook` is `on`, off when it is `off`, and, when `next.hook` is unset or `auto`, on exactly when the file `~/.claude/.groma-next-always` exists. groma SHALL NOT create or delete that file; it SHALL print the command to do so and the reason, in the user's language.

#### Scenario: Global flag, project opts out
- **WHEN** `~/.claude/.groma-next-always` exists and the project sets `next.hook: off`
- **THEN** neither hook prints anything in that project

### Requirement: Pill snippet
groma SHALL provide a one-line status-line pill that shows `next.sh --short` in the style of existing pills, as a snippet only.

#### Scenario: Pill offered
- **WHEN** the user agrees to the status-line pill
- **THEN** the summary shows the pill line to paste, and no status line file changes
