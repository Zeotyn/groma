---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [scripts/test.sh, tests/structure/, tests/scripts/, tests/invariant/, tests/evals/, .github/workflows/test.yml, .github/workflows/evals.yml]
---

# Test in four levels: structure, scripts, invariant, evals

## Context and Problem Statement

Skills are instructions executed by an agent, so unit tests alone cannot show that a run produces the right files. Agent runs cost tokens.

## Considered Options

* Four levels: structure checks, bats script tests, checksum invariant, headless agent evals on fixtures
* Script tests only
* Agent evals on every commit

## Decision Outcome

Chosen option: "Four levels", because the cheap levels run on every PR and evals run on demand or nightly.

### Consequences

* Good, because the never-overwrite rule and script behavior are checked on every PR.
* Bad, because only Claude Code is covered by automated evals; Copilot needs a manual protocol.

### Confirmation

`scripts/test.sh` runs before every commit; `scripts/test.sh evals` on the five fixtures.

## More Information

Derived by groma from existing code on 2026-11-04 (design decision D9); confirm or reject.
