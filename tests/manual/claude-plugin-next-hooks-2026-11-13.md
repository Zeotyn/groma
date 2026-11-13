# Manual protocol: next-action hooks from the plugin (C014 task 2.5)

Date: 2026-11-13. Claude Code 2.1.323, macOS 26.6.2, Apple M1 Max. Change: `c014-plugin-next-hooks`.

Repeat this protocol when Claude Code changes its hook behavior (see ADR 0050 for the version of the spike).

## Setup

Everything ran in throwaway folders under `/private/tmp/claude-502/c014/`. The user's real configuration was not touched:

- `HOME=/private/tmp/claude-502/c014/home`, so the flag file is `/private/tmp/claude-502/c014/home/.claude/.groma-next-always`, created with `touch`.
- `CLAUDE_CONFIG_DIR=/private/tmp/claude-502/c014/cfg`. No plugin was installed: the working tree was loaded with `--plugin-dir <repository>`. No settings file exists in the config dir or in the projects, before or after the runs.
- `proj`: a git repository with `.groma/config.yaml` (`schema: 1`, no `next` section) and a committed `openspec/changes/m001-first-release/tasks.md` with one done task and the open task `2.1 Release gate: tag v1.0.0 and publish`, so the milestone waits at its gate.
- `noproj`: an empty git repository without `.groma/`.

The isolated config has no login, so every run ended with `terminal_reason: api_error` before a model call (`total_cost_usd: 0`), as in the spike (`claude-plugin-bundles-2026-11-12.md`). Hooks still run, the stream reports them, and the session transcript records the request Claude Code built.

Command, run in the project folder:

```
claude -p "Reply with the single word ok. Do not use any tools." --model haiku --plugin-dir <repository> --output-format stream-json --verbose
```

## Runs

Three headless runs, no model call, cost 0.

| Run | Project | Flag file | `next.hook` | `SessionStart:startup` hook response | In the model request |
|---|---|---|---|---|---|
| 1 | `proj` | present | unset | exit 0, stdout `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"groma next action for this project (for orientation, act on it when the user asks): m001-first-release: milestone gate: 2.1 Release gate: tag v1.0.0 and publish"}}` | system text `SessionStart hook additional context: groma next action for this project (for orientation, act on it when the user asks): m001-first-release: milestone gate: 2.1 Release gate: tag v1.0.0 and publish` |
| 2 | `noproj` | present | no `.groma/` | exit 0, stdout and stderr empty | no groma text; no `.groma/` was created |
| 3 | `proj` | present | `off` | exit 0, stdout and stderr empty | no groma text |

Run 1 confirms the scenario "New session after a break": the agent's context holds the line that names the gate, without any settings edit. The session's skill list showed the plugin's skills (`groma:groma`, `groma:groma-agents`, ...), so the hook came from the plugin loaded with `--plugin-dir`.

Not reached: the `Stop` hook, because the runs ended at the API error before an answer. Its command in `hooks/hooks.json` was run by hand and by `tests/scripts/next-session.bats` with `CLAUDE_PLUGIN_ROOT` and `CLAUDE_PROJECT_DIR` set and printed `{"systemMessage":"▶ Next: m001-first-release: milestone gate: 2.1 Release gate: tag v1.0.0 and publish"}`. The display of a Stop hook's `systemMessage` without an extra turn was verified for settings hooks in `claude-stop-hook-2026-11-12.md`; plugin and settings hooks share the event. The sources `resume`, `clear` and `compact` were not run here (`resume` ran in the spike; `clear` and `compact` exist only in interactive sessions).

## Fast path

A plugin hook runs in every project where the plugin is enabled. Timing of the scripts alone, 100 runs in a row each, `sh <script> <project> </dev/null`:

| Case | `next-session.sh` | `next-stop.sh` |
|---|---|---|
| project without `.groma/` | 10.4 ms per run | 13.1 ms per run |
| `.groma/` with `next.hook: off` | 24.0 ms per run | 22.9 ms per run |
| for comparison: `sh -c :` on this machine | 14.3 ms per run | |

Without `.groma/` a hook costs one `sh` start and nothing measurable on top; the numbers sit inside the noise of the bare `sh` start. `tests/scripts/next-session.bats` asserts under 50 ms for both scripts (fastest of five runs; 11 to 12 ms here). With the next action on and a warm cache, `next-session.sh` took 80 ms.

## Verdict

- Hooks from the plugin's `hooks/hooks.json`, no settings edit: **verified by run** for `SessionStart` on `startup`.
- Next action in the agent's context: **verified by run** (model request in the transcript).
- Silent without `.groma/` and with `next.hook: off`: **verified by run**.
- `Stop` from the plugin: command **verified by hand and by test**, display from the C007 run and the docs.
