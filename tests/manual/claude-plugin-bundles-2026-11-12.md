# Spike: plugin bundles, plugin hooks and per-project plugin switches (S001)

Date: 2026-11-12. Claude Code 2.1.322, GitHub Copilot CLI 1.0.105. Change: `s001-plugin-bundles-hooks`.

## Setup

Everything ran in throwaway folders under `/private/tmp/claude-502/s001/`. The user's real configuration was not touched:

- Claude Code with an isolated config dir: `CLAUDE_CONFIG_DIR=/private/tmp/claude-502/s001/cfg`. Plugin installs, enables and disables went there; `~/.claude/plugins/installed_plugins.json` has no entry of the spike marketplace afterwards.
- Copilot CLI with an isolated home: `COPILOT_HOME=/private/tmp/claude-502/s001/cophome`.
- The isolated Claude config has no login, so every headless run ended with `terminal_reason: api_error` before a model call (`total_cost_usd: 0`). Hooks still run and the session transcript records the request Claude Code built, including system messages, so the hook questions were answered from that request, without a model reply.

Runs: 6 headless Claude runs and 2 Copilot runs, all at no cost (no model call happened).

## 1. Bundles: several plugins with different skill sets from one repository

Marketplace `groma-spike` at a copy of the repository layout (`.claude-plugin/plugin.json` named `groma`, `skills/` with the eight skills):

```json
{ "name": "groma-spike", "owner": { "name": "spike" },
  "plugins": [
    { "name": "groma", "source": "./", "version": "0.3.0" },
    { "name": "groma-docs", "source": "./", "version": "0.3.0",
      "skills": ["./skills/groma-detect", "./skills/groma-survey", "./skills/groma-lay-out"] },
    { "name": "groma-loop", "source": "./", "version": "0.3.0",
      "skills": ["./skills/groma-loop"] } ] }
```

Commands: `claude plugin validate <mkt>`, `claude plugin marketplace add <mkt>`, `claude plugin install <name>@groma-spike` for each, `claude plugin details <name>@groma-spike`.

| Plugin | Skills loaded | Always-on cost (projected by Claude Code) |
|---|---|---|
| `groma` | 8: all | ~633 tokens |
| `groma-docs` | 3: groma-detect, groma-lay-out, groma-survey | ~241 tokens |
| `groma-loop` | 1: groma-loop | (not recorded) |

`validate` passed (one warning: no icon). The docs confirm the rule: when an entry whose `source` is the marketplace root lists `skills` subdirectories, only those load and the default `skills/` scan is skipped (plugins reference, "Strict mode").

Observations:
- Every bundle shows the name from the root `plugin.json` (`groma 0.3.0`), so all bundles prefix their skills `groma:`. With all three installed, the session's skill listing showed each skill once.
- `claude plugin details` prints per-skill token estimates (always-on and on-invoke). Per skill, always-on ~50 to ~100 tokens, on-invoke ~500 (groma-detect) to ~3.2k (groma-loop). Useful for C010 and C011.

Verdict: **verified by run.** Bundles need no copies or symlinks: entries with `source: "./"` and a `skills` list of subdirectories.

## 2. Plugin hooks without settings edits

Test plugin `spikehooks` loaded with `--plugin-dir`, with `hooks/hooks.json`:

```json
{ "hooks": {
  "SessionStart": [ { "matcher": "startup|resume|clear|compact",
    "hooks": [ { "type": "command", "command": "sh \"${CLAUDE_PLUGIN_ROOT}/hooks/env.sh\" start-plain" } ] } ],
  "Stop": [ { "hooks": [ { "type": "command", "command": "sh \"${CLAUDE_PLUGIN_ROOT}/hooks/env.sh\" stop" } ] } ] } }
```

`env.sh` appends the event, the environment and stdin to a log file.

| Check | Result |
|---|---|
| Hook ran without any `settings.json` edit | yes, `SessionStart` fired on `startup` and `resume` |
| `CLAUDE_PLUGIN_ROOT` | the plugin folder |
| `CLAUDE_PROJECT_DIR` | the project folder (`cwd` of the session) |
| stdin | JSON with `session_id`, `transcript_path`, `cwd`, `hook_event_name`, `source` |
| `Stop` | not reached: the runs ended at the API error. The Stop hook's `systemMessage` path was verified for settings hooks in `tests/manual/claude-stop-hook-2026-11-12.md`; plugin and settings hooks share the event (docs) |

Verdict: **verified by run** for registration and environment; Stop display from the docs and the C007 run.

## 3. SessionStart output in the agent's context

| Form | Sources run | Where it appears in the model request |
|---|---|---|
| Plain stdout `GROMA-SPIKE-PLAIN: …` | startup | system message: `SessionStart:startup hook success: GROMA-SPIKE-PLAIN: …` |
| JSON `hookSpecificOutput.additionalContext` | startup, resume | system message: `SessionStart hook additional context: GROMA-SPIKE-JSON: …` |

Both forms reach the request that Claude Code sends to the model (read from the `api-request-blob` entry of the session transcript). The docs list `startup`, `resume`, `clear`, `compact` and `fork` as SessionStart sources and state that plain SessionStart stdout is added as context; `clear` and `compact` exist only in interactive sessions and were not run. Both forms are capped at 10,000 characters.

Verdict: **verified by run** for startup and resume, **docs only** for clear, compact and fork. `additionalContext` is the more explicit form (named "additional context", no "hook success" wording) and is preferred.

## 4. Copilot CLI plugin hooks

Two runs with `COPILOT_HOME` isolated and `--plugin-dir` failed before the session started: `Model "claude-haiku-4.5" from --model flag is not available` and the same for `gpt-5-mini`; the isolated home has no entitlement for the user's models. The hook log stayed empty.

Docs (docs.github.com, Copilot CLI plugin reference): legacy plugins ship hooks in `hooks.json` or `hooks/hooks.json` (or the `hooks` manifest field); Agent Plugins 1.0 plugins use `com.github.copilot/hooks/hooks.json`. Copilot reads `.claude-plugin/plugin.json` as a legacy manifest location.

Verdict: **docs only, not run.** Copilot plugins can carry hooks; whether a `sessionStart` hook's output reaches the agent is not documented and stays open.

## 5. Switching a plugin off for one project

```
cd <project>
claude plugin disable groma@groma-spike --scope local
```

writes `<project>/.claude/settings.local.json` with `"enabledPlugins": { "groma@groma-spike": false }` (local scope: not committed). With all three spike plugins disabled locally, the project's skill listing had 0 groma skills; another project still listed all 8.

Extra check for C016: a project holding `.claude/skills/groma-detect/` while the plugin is enabled lists the skill twice, as `groma-detect` and `groma:groma-detect`.

Verdict: **verified by run.** The hint for C016 is `claude plugin disable groma@groma --scope local`, run by the user in the project.
