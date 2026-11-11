---
status: proposed
date: 2026-11-11
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-lay-out/templates/docs/code-style.md, skills/groma-lay-out/references/code-style-tools.md, skills/groma-agents/templates/AGENTS.md]
origin: c005-code-style#D1
---

# Link tool configs from the code-style doc instead of restating their rules

## Context and Problem Statement

groma documents what a project is, not how its code is written. Agents guess indentation, naming and test placement on every change. Style knowledge sits in three layers: tool configs (`.editorconfig`, `.prettierrc`, `ruff.toml`), conventions that no tool enforces, and the decisions behind the tools. Where should `docs/code-style.md` draw the line?

## Considered Options

* "Enforced by tools" holds one row per tool with config path, check and fix command; the rules stay in the config. "Conventions" covers what no tool enforces, tagged `EXTRACTED` or `INFERRED` with a source path. "Decisions" links ADRs. The doc's `sources` list the config files.
* Summarize the tool rules inside the doc
* Make AGENTS.md the style home

## Decision Outcome

Chosen option: "link the configs, document only the conventions", because a config file is already the source of truth for what its tool enforces; a summary goes stale on every config change and duplicates it. Listing the config files as `sources` lets `docs-impact.sh` report the doc when a config changes. AGENTS.md has a 150-line budget and is loaded every turn, so it carries a pointer and the check commands only.

### Consequences

* Good, because the doc never contradicts a config; it links it.
* Good, because conventions, the part no tool captures, get a home with evidence.
* Bad, because a reader needs two files (doc and config) to see the whole style.

### Confirmation

`tests/evals/assert.sh` checks on the node-prisma fixture that the tools table names `.prettierrc` and `eslint.config.js` and that `sources` lists both. The AGENTS.md template carries the pointer and `{{style_checks}}`.

## More Information

From design decision D1 of c005-code-style. Related: ADR 0022 (docs impact through `sources`), ADR 0032.
