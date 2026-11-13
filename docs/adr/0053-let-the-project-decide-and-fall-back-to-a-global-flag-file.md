---
status: proposed
date: 2026-11-13
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/lib-changes.sh, skills/groma/templates/config.yaml, skills/groma/scripts/validate-config.sh, tests/scripts/next-session.bats, tests/scripts/validate-config.bats]
origin: c014-plugin-next-hooks#D2
---

# Let the project decide the next action and fall back to a global flag file

## Context and Problem Statement

With hooks in the plugin (ADR 0052), the next action could appear in every groma project at once. Users want one switch for all projects, and a project must still be able to opt in or out by itself. C007 had only `next.hook: on|off` per project, default `off`.

## Decision Drivers

* One switch for all projects
* A project can overrule it in a committed file
* A new project must not overrule the global switch by accident

## Considered Options

* Project `next.hook: on|off` wins; unset or `auto` follows the flag file `~/.claude/.groma-next-always`
* Project setting only
* Global flag only
* Keep the template default `off`

## Decision Outcome

Chosen option: "project wins, unset or `auto` follows the flag file", because it gives both switches a clear order.

Details:
- `next_on` in `lib-changes.sh` is the one implementation, used by `next-session.sh` and `next-stop.sh`: `on` is on, `off` is off, a missing key, an empty value (`hook:`) or `auto` is on exactly when `$HOME/.claude/.groma-next-always` exists. Any other value counts as off.
- The config template leaves `hook` unset and explains the three values in a comment. The validator accepts `on`, `off` and `auto` and rejects everything else with the line number.
- The scripts only test whether the flag file exists. groma never creates or removes it (ADR 0055).

### Consequences

* Good, because `touch ~/.claude/.groma-next-always` switches every groma project on, and `next.hook: off` keeps one project quiet.
* Bad, because a project initialized before this change with the old template carries `hook: off` and ignores the flag until that line is removed or set to `auto`.
* Neutral, because the flag path is fixed to `~/.claude/`; a `CLAUDE_CONFIG_DIR` elsewhere is not followed.

### Confirmation

`tests/scripts/next-session.bats` runs the table project on, off, `auto`, unset by flag present or absent against both hooks with a temporary `HOME`, and asserts that the flag file is neither created nor removed. `tests/scripts/validate-config.bats` covers `auto`, the unset template and rejected values.

## Pros and Cons of the Options

### Project setting only

* Bad, because the user asked for one switch for all projects.

### Global flag only

* Bad, because a project could not opt out.

### Keep the template default `off`

* Bad, because every new project would overrule the global flag.

## More Information

From design decision D2 of c014-plugin-next-hooks. Related: ADR 0052, ADR 0055.
