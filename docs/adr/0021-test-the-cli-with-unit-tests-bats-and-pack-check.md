---
status: proposed
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [cli/test/main.test.js, tests/scripts/cli.bats, scripts/test.sh]
origin: c003-groma-cli#D7
---

# Test the CLI with unit tests, stubbed bats runs and a pack check

## Context and Problem Statement

The CLI runs installers and writes into projects. Its tests must not need network access or real agents.

## Considered Options

* `node --test` unit tests for flag parsing, answer resolution (flags > TTY answers > recommended), recipe rendering, materialization and ownership
* bats end-to-end tests running `node bin/groma.js init --yes --print` on generated fixtures with stubbed `npx`, `claude` and `openspec` on PATH
* An `npm pack --dry-run` check in CI that the package contains `bin/`, `cli/`, `skills/` and nothing from `tests/` or `openspec/`

## Decision Outcome

Chosen option: "All three together", because each covers a different layer: logic, end-to-end behavior with the never-overwrite invariant, and package contents.

### Consequences

* Good, because no test needs the network or a logged-in agent.
* Bad, because the stubs must follow the real CLIs' behavior.

### Confirmation

`scripts/test.sh cli` runs the unit tests and the pack check. `tests/scripts/cli.bats` runs in `scripts/test.sh scripts`.

## More Information

From design decision D7 of c003-groma-cli. The three parts are listed as one testing decision, not as alternatives. Related: ADR 0008.
