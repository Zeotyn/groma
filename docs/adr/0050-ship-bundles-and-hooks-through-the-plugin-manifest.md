---
status: proposed
date: 2026-11-12
decision-makers: Eugen Waldschmidt
evidence: [tests/manual/claude-plugin-bundles-2026-11-12.md]
origin: s001-plugin-bundles-hooks
---

# Ship bundles and hooks through the plugin manifest

## Context and Problem Statement

M004 wants bundles of groma's skills in the Claude Code marketplace (C009), next-action hooks that ship with the plugin instead of settings files (C014), and a hint that switches the plugin off per project when the project holds its own copy of the skills (C016). Each depended on Claude Code behavior nobody had verified for groma.

## Decision Drivers

* No duplicated skill folders in the repository
* No writes to user or project settings by groma (ADR 0006)
* Hook output that reaches the agent once per session, measured cheaply

## Considered Options

* Marketplace entries with `source: "./"` and a `skills` list per bundle; hooks in `hooks/hooks.json` with `hookSpecificOutput.additionalContext` for SessionStart
* Per-bundle plugin folders with symlinks or generated copies of the skills
* Hooks written into `.claude/settings.local.json` per project (the C007 path)

## Decision Outcome

Chosen option: "marketplace entries with a `skills` list, hooks in `hooks/hooks.json`", because the spike showed that an entry whose source is the marketplace root loads only the listed skill folders, that plugin hooks run without any settings edit with `CLAUDE_PLUGIN_ROOT` and `CLAUDE_PROJECT_DIR` set, and that SessionStart output reaches the model request in both plain and `additionalContext` form.

Details:
- Bundles: `groma` (all eight skills), `groma-docs` (detect, survey, lay-out), `groma-loop` as entries in `.claude-plugin/marketplace.json`, each with `source: "./"` and a `skills` list. All bundles carry the root manifest's name, so their skills are prefixed `groma:`; bundles are alternatives, not add-ons.
- Hooks: `hooks/hooks.json` at the repository root; SessionStart prints `hookSpecificOutput.additionalContext`; Stop keeps the display-only `systemMessage`.
- Per-project switch: the user runs `claude plugin disable groma@groma --scope local` in the project; groma prints the command and never writes the setting.
- Copilot: plugins can ship hooks (`hooks/hooks.json`) per the docs; not run, so Copilot plugin hooks stay out of M004.

### Consequences

* Good, because bundles cost one marketplace entry each and no copies.
* Good, because the plugin's hooks work in every project where the plugin is enabled, without settings files.
* Good, because `claude plugin details` shows always-on and on-invoke token estimates per skill, a cheap input for C010 and C011.
* Bad, because a project copy of the skills and the enabled plugin list each skill twice (`groma-detect` and `groma:groma-detect`), so C016 must print the disable hint.
* Bad, because `clear` and `compact` SessionStart sources were verified from the docs only.

### Confirmation

`tests/manual/claude-plugin-bundles-2026-11-12.md` records every run. C009 adds a test that installs each bundle into an isolated config dir and checks `claude plugin details`.

## Pros and Cons of the Options

### Per-bundle folders with symlinks or copies

* Bad, because copies drift and symlinks outside a plugin folder break when a plugin is fetched from git into the cache.

### Hooks in settings files

* Bad, because they need a write per project and per machine, which groma avoids outside its own files.

## More Information

From spike s001-plugin-bundles-hooks. Related: ADR 0006, ADR 0042, ADR 0044, ADR 0047.
