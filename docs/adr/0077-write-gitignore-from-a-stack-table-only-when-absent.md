---
status: accepted
date: 2026-11-19
decision-makers: Eugen Waldschmidt
evidence: [skills/groma/references/gitignore.md, skills/groma/scripts/git-init.sh]
origin: c18-git-setup#D3
---

# Write `.gitignore` from a stack table, only when absent

## Context and Problem Statement

A first commit after `npm install` or a virtualenv would record `node_modules/` or `.venv/`. Where do ignore rules come from?

## Considered Options

* A stack reference table, written only when groma set up the repository and no `.gitignore` exists
* No `.gitignore`
* Templates fetched from github/gitignore
* An ignore file written freely by the agent

## Decision Outcome

Chosen option: "A stack reference table", because ignore rules are stack knowledge (ADR 0004). `references/gitignore.md` has rows of stack, manifests and patterns, with a stack `all` for editor and OS files; `git-init.sh` picks the rows of the named stacks, of manifests present at the root and of `all`. The skill and the CLI run the same script.

No file lost because the first commit would include dependencies. Fetching lost on network access at setup time. A free agent-written file lost because results would differ per run and entry point.

### Consequences

* Good, because both entry points write the same file.
* Bad, because the table covers common stacks only; others get the `all` rows.

### Confirmation

`tests/scripts/git-init.bats` checks the rows picked by stack and manifest and that an existing `.gitignore` stays byte-identical.
