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

## Implementation notes

- **Scripts.** `next-session.sh` is the SessionStart wrapper; `next_on` in `lib-changes.sh` holds the on/off rule for it and for `next-stop.sh`. Both test for `<project>/.groma/` before they source the library. An unknown `next.hook` value counts as off (the validator rejects it); an empty value (`hook:`) counts as `auto`. Both take an empty project argument as no argument.
- **Fast path, measured.** Without `.groma/`: 10 to 13 ms per run, the cost of one bare `sh` start on the test machine; with `next.hook: off`: 23 to 24 ms. The bats test asserts under 50 ms. Details in `tests/manual/claude-plugin-next-hooks-2026-11-13.md`.
- **ADR 0042.** D3 amends its scope: SessionStart is the one channel that gives text to the agent (ADR 0054 says so explicitly); every other channel stays display-only.
- **Context text.** The `additionalContext` is the long line behind the label "groma next action for this project (for orientation, act on it when the user asks):", so that the one channel that reaches the agent does not read as an instruction (ADR 0042).
- **hooks.json.** Listed in no manifest: Claude Code finds `hooks/hooks.json` at the plugin root by itself (ADR 0050). Not in `package.json` `files`: the npm package is the CLI, which copies skill folders; the plugin is fetched from the repository. `tests/structure/check.py hooks` guards the file (events, matcher, commands that run a shipped script and end in `|| true`). The commands carry `2>/dev/null` and a 10 second timeout; the check asserts both.
- **Behavior change for C007 installs.** A missing `next.hook` used to mean off and now means `auto`. A project with the settings-file hook and no `next.hook: on` would switch on when the flag file exists; groma-agents has always set `next.hook: on` with that hook, so nothing changes for them. A 0.3.0 config carries `hook: off` from the old template and stays off until the line is removed; `skills/groma/references/upgrades.md` has a row for update mode (version column `Unreleased`, to be renamed at release).
- **Plugin plus settings hook (review finding).** Claude Code starts matching hooks in parallel, so a project with both starts `next-stop.sh` twice at the same moment, and the debounce state alone let both copies print in 3 to 4 of 20 runs. Two guards: the plugin command passes `--plugin`, with which `next-stop.sh` exits when `<project>/.claude/settings.local.json` or `<project>/.claude/settings.json` names `next-stop.sh`; and every copy takes the lock folder `.groma/.cache/next-stop.lock` before it reads the state (a second copy exits silently, a lock older than 15 seconds is taken over, the state is written through a temporary file and `mv`). After the fix: 0 of 20 in the reviewer's script and exactly one line in each of 20 rounds of the bats test. update mode and groma-agents suggest removing the settings block.
- **Plugin detection in groma-agents.** `claude` in `agents_via_plugin`, or the skill itself runs from a plugin folder. The skill does not run `claude plugin list` and does not look into `~/.claude`.
- **Pill (D5).** `templates/statusline-pill.sh`: one line, white on blue 256-color pill. It takes a `{{next_script_pattern}}` instead of a fixed path, because a plugin install lives in a version-named cache folder; the version is a `*` and the highest version wins (`sort -V`). A child `sh -c` expands the pattern, because a zsh status line aborts on a pattern without a match (review finding). The existing pills of the user's status line were not read (outside the project), so the colors are a neutral guess. ADR 0056 records D5 although the task named D1 to D4, because D5 has an alternative and `docs.adr_from` is `design-alternatives`.
- **Manual protocol.** Three headless runs with an isolated `HOME` and `CLAUDE_CONFIG_DIR`, no login, so no model call and no cost; the context was read from the model request in the transcript, as in S001. The Stop hook was not reached in those runs; its command is covered by the bats test.
- **CHANGELOG.** Not edited in this change: the integrator writes the `[Unreleased]` entry, because parallel changes touch the same section.
- **Open.** Whether Cursor or Codex read a Claude-format `hooks/hooks.json` from the same repository; whether the flag should follow `CLAUDE_CONFIG_DIR`.
