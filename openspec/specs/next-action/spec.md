# next-action Specification

## Purpose
Names the single next action for a project at any moment, deterministically and without tokens, and shows it where the user already looks.
## Requirements
### Requirement: Next-action ladder
groma SHALL provide a read-only script that prints at most one next action: the first rung that applies, in this order:
1. a rebase or merge in progress
2. an active change with all tasks done and docs impact open
3. an active change with all tasks done
4. uncommitted files
5. a milestone at its gate
6. local commits on the main branch not pushed, unless `git.push` is `never`
7. an ADR still proposed after its origin change was archived
8. the active change with the most recent commit and open tasks

It SHALL print nothing when no rung applies. It SHALL use only local files and git state.

#### Scenario: Unpushed before ADR
- **WHEN** the working tree is clean, no change is done, M002 has active children, `main` has 3 unpushed commits and ADR 0015 is proposed with its change archived
- **THEN** the script prints the unpushed action

#### Scenario: Nothing to do
- **WHEN** no rung applies
- **THEN** the script prints nothing and exits 0

### Requirement: Output formats
`--short` SHALL print at most 20 characters without a trailing newline problem for status lines, for example `push 3` or `verify c007`. `--long` SHALL print one sentence with the exact command, for example "Push 3 commits on main: git push". `--json` SHALL print the rung id, the short and the long text.

#### Scenario: Short form
- **WHEN** rung 3 applies to `c007-cache`
- **THEN** `--short` prints `verify c007` and `--long` prints "c007-cache: all tasks done, verify: /opsx:verify c007-cache"

### Requirement: Fast and cached
The script SHALL finish in under 300 ms on a repository with 20 changes when its cache is valid. The cache SHALL be keyed on `HEAD`, the `git status --porcelain` output and the modification time of the changes folder. It SHALL live in `.groma/.cache/`, which ignores itself through a `.groma/.cache/.gitignore` containing `*`, so running the script never adds an untracked file.

#### Scenario: Cache hit
- **WHEN** the script runs twice with no change to `HEAD`, working tree or changes folder
- **THEN** the second run reads the cache and does not call the status script

### Requirement: Display only, never steer the agent
Hook adapters SHALL show the next action to the user only. They SHALL NOT use any channel that blocks the agent, retries its turn or sends a follow-up message to the agent. An agent whose CLI offers no such display-only channel SHALL get no hook.

#### Scenario: Cursor
- **WHEN** the configured agents include cursor
- **THEN** no cursor hook is installed and the AGENTS.md fallback line is the only mechanism

### Requirement: Debounced Stop hook
The Claude Code Stop hook SHALL output the long line as `systemMessage` only when it differs from the last shown line or when the last showing is older than `next.reshow_minutes` (default 30), and SHALL output nothing otherwise. It SHALL be installed only after the user agrees, into `.claude/settings.local.json` when groma creates that file, or as a snippet otherwise.

#### Scenario: Same suggestion twice
- **WHEN** two answers in a row end with the same next action within 30 minutes
- **THEN** only the first answer shows the line

### Requirement: Status-line snippet
groma SHALL NOT modify a user's status line configuration or script. When the user wants the status-line pill, groma SHALL print a snippet that calls the script with `--short` for the session's working directory, in the findings report and in the summary.

#### Scenario: User with own statusline.sh
- **WHEN** `~/.claude/settings.json` has a `statusLine` command
- **THEN** the file and the script are unchanged and the summary shows the snippet to add

### Requirement: Hook adapters as data
Per-agent hook support SHALL be described in the agent table with event name, config file, output format and status (`stable`, `experimental`, `none`). groma SHALL offer hooks only for `stable` agents by default and for `experimental` agents only when the user asks, marked untested and given as a snippet.

#### Scenario: Gemini requested
- **WHEN** the user asks for the hook in Gemini CLI
- **THEN** groma prints the experimental adapter as a snippet only after a warning that it is untested

### Requirement: Hooks in the plugin
The groma Claude Code plugin SHALL register its next-action hooks through its own `hooks/hooks.json`: a `SessionStart` hook for startup, resume, clear and compact, and the debounced `Stop` hook. Both SHALL exit without output when the project has no `.groma/` folder or the next action is off. No settings file SHALL be written when the plugin is installed.

#### Scenario: Project without groma
- **WHEN** a session starts in a repository without `.groma/` and the plugin is enabled
- **THEN** both hooks print nothing and return within 50 ms

#### Scenario: Plugin and settings-file hook together
- **WHEN** the plugin is enabled in a project whose `.claude/settings.local.json` also runs `next-stop.sh` on Stop, and both hooks start at the same moment
- **THEN** the next-action line is shown at most once

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

