Milestone: m003

## Why

Users and agents lose track of what comes next. Examples: a change sits at "all tasks done" without verify, commits stay unpushed, a milestone waits for its release gate. `status.sh` lists reminders, but only when someone runs it, and it prints every open item instead of naming the one to act on. One deterministic next action, always visible and costing no tokens, turns the reminders into something people actually see and act on.

## What Changes

- New read-only script `next.sh` in groma-methodology. It prints at most one next action, the first matching rung of a fixed ladder:
  1. rebase or merge in progress
  2. change done but docs open
  3. change done → verify
  4. uncommitted work
  5. milestone gate
  6. unpushed commits (unless `git.push: never`)
  7. proposed ADR whose change is archived
  8. active change without progress

  `--short` prints at most 20 characters for a status-line pill; `--long` prints a sentence with the command. A cache keyed on `HEAD` and the working-tree state keeps a run under 300 ms.
- **Claude Code status line:** groma never edits the user's status line script. It prints a snippet that adds a `▶ <short>` pill.
- **Claude Code Stop hook** (opt-in, in `.claude/settings.local.json`): shows the long line as `systemMessage` only when the suggestion changed, or 30 minutes after it was last shown. It never uses blocking, retry or follow-up channels.
- **Per-agent hook adapters** as data in `agents.yaml`, with a status per agent:
  - `stable` (claude)
  - `spike` (copilot)
  - `experimental` (gemini, codex)
  - `none` (cursor)
- **Fallback everywhere:** an AGENTS.md line and the CLI command `npx groma next`.
- **Spike first:** does Copilot CLI's `agentStop` output reach the user without starting another turn? The result sets copilot's adapter status.

## Capabilities

### New Capabilities
- `next-action`: the ladder, output formats, cache, display channels and their safety rule, debounce, adapters.

### Modified Capabilities
- `cli`: new command `groma next`.
- `agent-instructions`: next-action fallback line and the hook and status-line offer.
- `project-config`: `next` settings (`hook`, `reshow_minutes`).

## Impact

- New: `skills/groma-methodology/scripts/next.sh`, `tests/scripts/next.bats`, `skills/groma-agents/templates/claude-stop-hook.json`, `templates/statusline-snippet.sh`, `.groma/.gitignore` template.
- Changed: `skills/groma/agents.yaml` (hook adapters), `cli/main.js` and a new `cli/next.js`, groma-agents SKILL and AGENTS.md template, config template and validator, `upgrades.md`.
- Depends on C006 (`git.push`) and F002 (milestone gate and repository state in `status.sh`).

## Docs impact

- `docs/architecture.md`: next.sh and display channels; `docs/concept.md`: next action; `docs/glossary.md`: next action, ladder.
- ADRs for D1 (display only, never block), D2 (ladder in a script), D4 (status line by snippet).
