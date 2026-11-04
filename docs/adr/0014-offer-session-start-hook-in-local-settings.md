---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-loop/SKILL.md, skills/groma-methodology/scripts/status.sh]
origin: c002-review-loop#D6
---

# Offer the status hook in local, uncommitted Claude settings

## Context and Problem Statement

A SessionStart hook that runs `status.sh` needs the absolute path of the installed script, which differs per machine.

## Considered Options

* Hook in `.claude/settings.local.json`, offered only
* Hook in the shared `.claude/settings.json`

## Decision Outcome

Chosen option: "Hook in `.claude/settings.local.json`", because the machine-specific path must not be committed to the shared settings. It is written only when the file does not exist (additive) or after explicit approval for an existing file.

### Consequences

* Good, because the shared settings stay free of local paths.
* Bad, because each team member sets up the hook on their own.

### Confirmation

Review of the hook offer in the skill. Checksum invariant in `tests/invariant/checksum.sh` covers the additive rule.

## More Information

From design decision D6 of c002-review-loop. Related: ADR 0006 (same rule as D11 of C001).
