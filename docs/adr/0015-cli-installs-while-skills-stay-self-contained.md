---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [bin/groma.js, cli/skills.js, package.json]
origin: c003-groma-cli#D1
---

# Let the CLI install skills while the skills stay self-contained

## Context and Problem Statement

`groma init` should set up a project without agent involvement, yet skills must keep working when installed by plugin, `npx skills` or `install.sh`.

## Considered Options

* Hybrid: the npm package contains `skills/` verbatim and the CLI copies whole skill folders; skills call their own `scripts/*.sh`
* OpenSpec's full model, where skills call `npx groma ...`

## Decision Outcome

Chosen option: "Hybrid", because a plugin or `npx skills` install then behaves the same as a CLI install. The full model would port the tested sh logic to Node and make every skill depend on Node.

### Consequences

* Good, because skills work with or without the CLI.
* Bad, because install paths can drift apart (see ADR 0016 for the shared recipes that limit this).

### Confirmation

`scripts/test.sh cli` runs `npm pack --dry-run` and checks the package contents. `tests/scripts/cli.bats` runs the CLI end to end.

## More Information

From design decision D1 of c003-groma-cli. Related: ADR 0003.
