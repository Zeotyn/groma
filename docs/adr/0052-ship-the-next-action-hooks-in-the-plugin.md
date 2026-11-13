---
status: accepted
date: 2026-11-13
decision-makers: Eugen Waldschmidt
evidence: [hooks/hooks.json, skills/groma-methodology/scripts/next-session.sh, skills/groma-methodology/scripts/next-stop.sh, tests/scripts/next-session.bats, tests/structure/check.py, tests/manual/claude-plugin-next-hooks-2026-11-13.md]
origin: c014-plugin-next-hooks#D1
---

# Ship the next-action hooks in the plugin

## Context and Problem Statement

The next action (C007) reaches Claude Code only after groma-agents wrote `.claude/settings.local.json` or the user pasted a snippet, once per project and per machine. groma is also a Claude Code plugin, and a plugin can carry its own hooks (ADR 0050). Where do the next-action hooks live so that they work wherever the plugin is enabled?

## Decision Drivers

* No settings edit when the plugin is installed
* A plugin hook runs in every project, also in those that never saw groma
* Installs without the plugin keep working

## Considered Options

* `hooks/hooks.json` in the plugin, with a first-line check for `<project>/.groma/`
* Keep writing `.claude/settings.local.json` per project
* Edit the user's global settings

## Decision Outcome

Chosen option: "`hooks/hooks.json` in the plugin", because it needs no write at all and follows the plugin to every machine and project.

Details:
- `hooks/hooks.json` at the repository root registers `SessionStart` (matcher `startup|resume|clear|compact`, `next-session.sh`) and `Stop` (`next-stop.sh --plugin`). The commands read `sh "${CLAUDE_PLUGIN_ROOT}/skills/groma-methodology/scripts/<script>" "$CLAUDE_PROJECT_DIR" 2>/dev/null || true`, each with a 10 second timeout.
- Both scripts test for `<project>/.groma/` before they source anything and exit 0 without output when it is missing; then they apply the on/off rule (ADR 0053).
- The settings-file path of C007 (groma-agents step 5, `claude-stop-hook.json`) stays for installs without the plugin.
- A project can have both the plugin and the settings-file hook, and Claude Code starts matching hooks in parallel. Two guards keep the line from showing twice: with `--plugin`, `next-stop.sh` exits when `<project>/.claude/settings.local.json` or `<project>/.claude/settings.json` names `next-stop.sh` (a read inside the project), and every copy takes the lock folder `.groma/.cache/next-stop.lock` before it reads the debounce state, so a second copy exits silently. A lock older than 15 seconds is taken over; the state is written through a temporary file and `mv`.
- The npm package does not ship `hooks/`: the CLI copies skill folders, and the plugin is fetched from the repository.

### Consequences

* Good, because enabling the plugin is the whole setup; no file in the project or in `~` changes.
* Good, because a project without `.groma/` pays one `sh` start per hook and nothing measurable on top: 10 to 13 ms per run, the same as a bare `sh -c :` on the test machine (`tests/manual/claude-plugin-next-hooks-2026-11-13.md`).
* Bad, because a project that has both the plugin and the settings-file hook starts `next-stop.sh` twice per answer, in parallel. Without the guards both copies printed the line in 3 to 4 of 20 runs; with them, in 0 of 20. A Stop hook in the user's global settings is outside the project and is caught by the lock only.
* Neutral, because the Cursor and Codex manifests point at the same repository; whether those CLIs read a Claude-format `hooks/hooks.json` was not checked.

### Confirmation

`tests/scripts/next-session.bats` runs the commands of `hooks/hooks.json` with `CLAUDE_PLUGIN_ROOT` and `CLAUDE_PROJECT_DIR` set, asserts that both scripts print nothing and return within 50 ms without `.groma/`, and starts two copies of `next-stop.sh` together 20 times, expecting exactly one line each time. `tests/structure/check.py hooks` fails when the file is missing, registers other events, runs a script that is not shipped, or has a command without `2>/dev/null || true` or a timeout.

## Pros and Cons of the Options

### Keep writing `.claude/settings.local.json`

* Bad, because it is a write per project and per machine, and impossible for users who never run the write step.

### Edit the user's global settings

* Bad, because it writes outside the project, against ADR 0006.

## More Information

From design decision D1 of c014-plugin-next-hooks. Related: ADR 0006, ADR 0046, ADR 0050.
