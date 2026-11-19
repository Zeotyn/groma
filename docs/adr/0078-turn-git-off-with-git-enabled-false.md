---
status: accepted
date: 2026-11-19
decision-makers: Eugen Waldschmidt
evidence: [skills/groma/templates/config.yaml, skills/groma/scripts/validate-config.sh, skills/groma-agents/SKILL.md, skills/groma-loop/SKILL.md, skills/groma-lay-out/scripts/docs-impact.sh]
origin: c18-git-setup#D4
---

# Turn git off consistently with `git.enabled: false`

## Context and Problem Statement

A user who declines the repository still got a Git workflow section, a loop that discovered the missing repository step by step, and a docs gate that exited 2. How is "no git" recorded and honoured?

## Considered Options

* A key `git.enabled`, default `true`
* Keep the defaults and let each step discover the missing repository
* A separate key `vcs: none`

## Decision Outcome

Chosen option: "A key `git.enabled`, default `true`", because it lives with the other git settings and existing configs keep their meaning. With `false`, groma-agents writes no Git workflow section, groma-loop skips every git step and says so once, and `docs-impact.sh` reports the ADR candidates with a `note` instead of exiting 2; the same `note` path covers a repository before its first commit.

Discovering per step lost because AGENTS.md would describe a workflow that does not exist. `vcs: none` lost as a second place for git settings.

### Consequences

* Good, because the docs gate works from the first change on, with or without git.
* Bad, because changed paths cannot be compared without git, so the impact part stays empty.

### Confirmation

`tests/scripts/validate-config.bats` checks the key; `tests/scripts/docs-impact.bats` the report outside git.
