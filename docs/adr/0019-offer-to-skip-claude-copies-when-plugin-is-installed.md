---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [cli/init.js, cli/exec.js, cli/config.js]
origin: c003-groma-cli#D5
---

# Offer to skip Claude skill copies when the groma plugin is installed

## Context and Problem Statement

A user may have groma as a Claude Code plugin already. Materializing skill copies as well would duplicate them.

## Considered Options

* `init` runs `claude plugin list` when `claude` is an agent. If `groma` is listed, it offers to skip Claude materialization (default skip) and records `agents_via_plugin` in the config

No alternatives were recorded.

## Decision Outcome

Chosen option: "Detect the plugin and default to skip", because it avoids two copies of the same skills. The config validator accepts the `agents_via_plugin` key.

### Consequences

* Good, because the plugin and the CLI coexist.
* Bad, because `init` depends on the output of `claude plugin list`.

### Confirmation

`cli/test/init.test.js` and `tests/scripts/cli.bats` with a stubbed `claude` on PATH.

## More Information

From design decision D5 of c003-groma-cli. No alternatives were recorded. Related: ADR 0015.
