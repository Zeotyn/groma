Milestone: m004

## Why

The next action (C007) appears only after groma-agents writes `.claude/settings.local.json` or the user copies a snippet, per project and per machine. Plugins such as i-have-adhd and ponytail ship their hooks inside the plugin and switch them with a flag file, so they work everywhere the plugin is enabled. groma is a Claude plugin too and can do the same, which also serves people who use groma without the CLI.

## What Changes

- The groma plugin ships `hooks/hooks.json` with:
  - `SessionStart` (startup, resume, clear, compact): prints `next.sh --long` into the agent's context, once per session;
  - `Stop`: the existing debounced, display-only `next-stop.sh`.
- Both exit at once when the project has no `.groma/` or the next action is off.
- On/off: the project's `next.hook: on|off` wins; when unset, the global flag file `~/.claude/.groma-next-always` switches it on. The config template leaves `next.hook` unset; the validator accepts `auto` as the explicit unset value.
- groma never creates the flag file: it prints the command and the reason (it deliberately does not look outside the project).
- A ready-made status-line pill line in the style of existing pills, as a snippet.
- The settings-file path from C007 stays for installs without the plugin.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `next-action`: hooks ship in the plugin; SessionStart reaches the agent; on/off by project and global flag; pill snippet.
- `project-config`: `next.hook` gains `auto` and an unset default.
- `agent-instructions`: the offer prints the flag command instead of writing settings when the plugin is installed.

## Docs impact

README "Next action"; `docs/architecture.md`; ADRs for D1 to D4 of the design; `docs/data-model.md` (`next.hook` values).

## Impact

`hooks/hooks.json` (plugin root, per S001), `skills/groma-methodology/scripts/next-stop.sh` and a SessionStart wrapper, `skills/groma/templates/config.yaml`, `validate-config.sh`, `skills/groma-agents/SKILL.md`, the status-line snippet template.
