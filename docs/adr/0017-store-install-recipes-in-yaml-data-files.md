---
status: proposed
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/methodologies.yaml, skills/groma/agents.yaml, skills/groma-skills/catalog.yaml, cli/recipes.js]
origin: c003-groma-cli#D3
---

# Store install recipes in YAML data files shared by CLI and skills

## Context and Problem Statement

Install command lines lived in Markdown prose. The CLI and the skills need one source of truth for them.

## Considered Options

* YAML data files: `methodologies.yaml` (detect, requires, init, agent_ids, touches, interactive, docs_link), `agents.yaml` (skills_dir, home_marker, npx_skills_id, instruction file) and `catalog.yaml` (schema unchanged)

No alternatives were recorded.

## Decision Outcome

Chosen option: "YAML data files", because the Markdown references keep the explanations and point to the data files, and command lines no longer live in prose. Skills read the YAML with the agent's own tools.

### Consequences

* Good, because CLI and skills render the same recipes.
* Bad, because stack knowledge now sits in two forms, prose and data.

### Confirmation

`cli/test/recipes.test.js` tests rendering. The design also plans a test that compares `--print` output with the documented commands.

## More Information

From design decision D3 of c003-groma-cli. No alternatives were recorded. Related: ADR 0004.
