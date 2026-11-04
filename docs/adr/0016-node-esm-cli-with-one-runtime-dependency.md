---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [bin/groma.js, cli/main.js, package.json]
origin: c003-groma-cli#D2
---

# Write the CLI in Node ESM with one runtime dependency

## Context and Problem Statement

The CLI needs prompts, YAML parsing and tests without a heavy dependency tree.

## Considered Options

* Node >= 22, ESM, prompts via `node:readline/promises`, tests via `node --test`, one runtime dependency `yaml` (pinned)
* `@clack/prompts` for nicer prompts
* JSON data files instead of YAML

## Decision Outcome

Chosen option: "Node >= 22 with `yaml` as the only runtime dependency", because readline is enough for prompts. `@clack/prompts` is rejected for now as a second dependency. JSON is rejected because catalog and config are hand-edited.

### Consequences

* Good, because the install footprint stays small.
* Bad, because prompts are plainer, and Node < 22 is not supported.

### Confirmation

`cli/test/*.test.js` run with `node --test` through `scripts/test.sh cli`. Review of `package.json` dependencies.

## More Information

From design decision D2 of c003-groma-cli. Related: ADR 0005, ADR 0008.
