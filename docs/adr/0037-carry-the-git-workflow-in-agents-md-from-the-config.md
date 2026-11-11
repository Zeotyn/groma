---
status: proposed
date: 2026-11-11
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-agents/templates/AGENTS.md, skills/groma-agents/SKILL.md, skills/groma/templates/config.yaml, skills/groma/references/upgrades.md]
origin: c006-git-workflow#D1
---

# Carry the git workflow in AGENTS.md, sourced from the config

## Context and Problem Statement

groma had no git policy. Agents read AGENTS.md, not `.groma/config.yaml`, so a setting that lives only in the config never reaches an agent that is not running groma-loop, and an orchestrator that says "merge branch X" gets a merge commit in a project that wants a linear history. Where does the integration rule live so that every agent, in and outside the loop, follows the same one?

## Considered Options

* The config holds the `git` settings; groma-agents renders a "Git workflow" section from them into AGENTS.md, including the sentence that a request to "merge" a branch means the configured sequence; re-running groma regenerates the section only in an AGENTS.md that groma created, other files get a snippet
* The config only, read by groma-loop
* A git hook that rejects merge commits

## Decision Outcome

Chosen option: "config as source, AGENTS.md as carrier", because AGENTS.md is the one file every agent and every orchestrator-driven session reads, while the config stays the single place to change the setting. A config-only rule is invisible to agents outside the loop, which is how the unwanted merge commit happened. A hook lives in `.git/hooks`, outside groma's write scope, and an agent sees it only when it fails.

### Consequences

* Good, because one setting reaches every agent, and the sentence about "merge" requests removes the ambiguity that caused the problem.
* Good, because the section is regenerated from the config, so the two cannot drift when groma owns the file.
* Bad, because an AGENTS.md that groma did not create needs the section applied by hand from the findings report (ADR 0006).

### Confirmation

`tests/evals/assert.sh` (loop-openspec) checks that the loop integrates as AGENTS.md says; the agent-instructions spec scenario "Rebase project" names the rendered commands.

## More Information

From design decision D1 of c006-git-workflow. Related: ADR 0006, ADR 0036 (the same pointer pattern for the code style).
