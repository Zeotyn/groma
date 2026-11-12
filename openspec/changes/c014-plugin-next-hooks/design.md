## Context

C007 ships `next.sh`, `next-stop.sh` (debounced Stop `systemMessage`) and a status-line snippet; the Stop hook is installed through `.claude/settings.local.json` or a snippet. S001 confirms how plugin hooks register and whether SessionStart stdout reaches the agent.

## Goals / Non-Goals

**Goals:**
- Next action with no settings edit when the plugin is installed.
- One clear on/off rule.
- The agent knows at session start where the work stands.

**Non-Goals:**
- Writing anything outside the project.
- Hooks for agents without a confirmed channel.

## Decisions

### D1: Hooks ship in the plugin
`hooks/hooks.json` in the groma plugin registers `SessionStart` and `Stop`. Each command first checks for `<project>/.groma/` and the on/off rule and exits within milliseconds otherwise, because a plugin hook runs in every project where the plugin is enabled. The settings-file path from C007 stays for installs without the plugin.

Alternatives: keep writing `settings.local.json` (rejected: per project and per machine, and impossible without the CLI's write step); a global settings edit (rejected: outside the project, ADR 0006).

S001 result (ADR 0050): plugin hooks in `hooks/hooks.json` run without any settings edit; a hook command gets `CLAUDE_PLUGIN_ROOT` (plugin folder) and `CLAUDE_PROJECT_DIR` (project folder), and stdin JSON with `cwd` and `source`. Use `"${CLAUDE_PLUGIN_ROOT}"/skills/groma-methodology/scripts/…` in the commands.

### D2: Project wins, global flag as fallback
`next.hook: on` or `off` in `.groma/config.yaml` decides. When it is unset (or `auto`), the flag file `~/.claude/.groma-next-always` switches the hooks on. The config template leaves the key unset.

Alternatives: project only (rejected: the user asked for one switch for all projects); global only (rejected: a project must be able to opt out); template default `off` (rejected: it would override the global flag in every new project).

### D3: SessionStart reaches the agent, once per session
The SessionStart hook prints the long line so the agent starts knowing the next step, after a break, a `/clear` or a compaction. This extends ADR 0042, which covered the Stop channel: one line per session costs almost nothing and does not steer each turn. Stop stays display-only and debounced.

Alternatives: SessionStart display-only (rejected: the agent would still not know where the work stands); inject on every prompt (rejected by ADR 0042: tokens on every turn).

S001 result (ADR 0050): both plain stdout and `hookSpecificOutput.additionalContext` reach the model request (verified for startup and resume; clear, compact and fork from the docs). Print the JSON `additionalContext` form: it is labelled "additional context" instead of "hook success". Output is capped at 10,000 characters. Matcher: `startup|resume|clear|compact`.

### D4: Commands instead of writes outside the project
groma prints `touch ~/.claude/.groma-next-always` (and `rm` to switch off) with the reason that it deliberately does not look or write outside the project. The same applies to the status-line pill.

Alternatives: create the flag file after a yes (rejected: ADR 0006 scope would grow to `~`).

### D5: Pill snippet in the style of existing pills
groma ships a one-line pill (`▶ <next.sh --short>`) for status lines that already render pills, plus the standalone script from C007. ADR 0044 holds: groma never edits a status line.

Alternatives: only the standalone script (rejected: users with their own status line would have to adapt it).

## Risks / Trade-offs

- [A plugin hook slows every session in every project] → the no-`.groma/` check is the first line; a test asserts it returns within 50 ms.
- [SessionStart behavior changes between Claude Code versions] → S001 records the version; a manual protocol is repeated on upgrades.
