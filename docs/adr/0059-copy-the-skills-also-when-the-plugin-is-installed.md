---
status: proposed
date: 2026-11-13
decision-makers: Eugen Waldschmidt
evidence: [skills/groma/scripts/materialize.sh, skills/groma/SKILL.md, cli/init.js, cli/test/init.test.js]
origin: c016-agent-only-init#D3
---

# Copy the skills also when the Claude plugin is installed, and print how to switch it off

## Context and Problem Statement

The groma Claude Code plugin and a project copy both provide the skills, so Claude Code lists each one twice (`groma-detect` and `groma:groma-detect`, verified in ADR 0050). ADR 0019 therefore skipped the Claude copies by default when the plugin was installed. But then the repository holds no Claude skills, and a teammate without the plugin gets none.

## Decision Drivers

* The project copy is the one teammates get
* groma never edits settings it did not create (ADR 0006)
* The CLI and `/groma` behave the same

## Considered Options

* Copy anyway and print the command that switches the plugin off for this project
* Keep skipping Claude when the plugin is present
* Write a project setting that disables the plugin

## Decision Outcome

Chosen option: "copy anyway and print the command", because the duplicate listing is harmless and the user can remove it with one command, while a missing copy leaves the team without skills.

Details:
- `materialize.sh` prints a `plugin` line with `claude plugin disable groma@groma --scope local` when `claude` is among the agents and the plugin is active: the script runs from a plugin folder, or `claude plugin list` shows `groma@`. `/groma` passes the command on in the user's language with the reason, and repeats it once in the summary.
- `groma init` changes its default from skip to copy and prints the same command. Interactive users can still answer no; then nothing is copied for Claude and the config records `agents_via_plugin: [claude]`, as before.
- groma never runs the command and never writes `.claude/settings.local.json` or any other settings file.

This replaces the default of ADR 0019; its detection and the `agents_via_plugin` key stay.

### Consequences

* Good, because a repository set up by a plugin user works for teammates without the plugin.
* Bad, because a user who ignores the hint sees every groma skill twice in Claude Code.
* Bad, because the command depends on Claude Code (verified on 2.1.322 in ADR 0050).

### Confirmation

`tests/scripts/materialize.bats` (plugin present, run from a plugin folder) and `cli/test/init.test.js` check that the copies are written, the command is printed, `claude plugin disable` is never called and no settings file appears.

## Pros and Cons of the Options

### Keep skipping Claude when the plugin is present

* Bad, because the team gets no Claude skills from the repository.

### Write a project setting that disables the plugin

* Bad, because groma does not edit settings it did not create (ADR 0006), and `.claude/settings.local.json` belongs to the user.

## More Information

Decision D3 of `openspec/changes/c016-agent-only-init/design.md`. Related: ADR 0006, ADR 0019, ADR 0050, ADR 0058.
