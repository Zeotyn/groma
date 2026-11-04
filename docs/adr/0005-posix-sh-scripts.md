---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-detect/scripts/detect.sh, skills/groma-survey/scripts/freshness.sh, skills/groma/scripts/validate-config.sh, scripts/test.sh, .github/workflows/test.yml]
---

# Write runtime scripts in POSIX sh

## Context and Problem Statement

Skills need a few deterministic helpers (detection, freshness, config validation, change ids). They run on user machines with unknown toolchains.

## Considered Options

* POSIX `sh`, checked with `shellcheck -s sh`
* Node.js scripts
* Python scripts

## Decision Outcome

Chosen option: "POSIX `sh`", because it is available wherever the agents run (except plain Windows) and needs no install. Python is used only in the test suite via `uv run`.

### Consequences

* Good, because no runtime dependency beyond `git`.
* Bad, because YAML parsing in sh is limited; plain Windows falls back to the agent applying the reference tables.

### Confirmation

`shellcheck -s sh` passes for every `*.sh`; bats tests in `tests/scripts/`.

## More Information

Derived by groma from existing code on 2026-11-04; confirm or reject.
