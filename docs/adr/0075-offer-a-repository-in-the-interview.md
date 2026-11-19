---
status: proposed
date: 2026-11-19
decision-makers: Eugen Waldschmidt
evidence: [skills/groma/scripts/git-init.sh, skills/groma/SKILL.md, cli/init.js, tests/scripts/git-init.bats]
origin: c18-git-setup#D1
---

# Offer a repository in the interview, recommended for greenfield only

## Context and Problem Statement

On a folder outside git, `/groma` asked no git question but still wrote git defaults and a Git workflow section, and the docs gate of the first change failed without a repository. How does a project without git get one, without groma running commands with lasting side effects unasked?

## Considered Options

* Ask in the interview, before the integration question; yes recommended for greenfield, no for brownfield
* Always run `git init` without asking
* Only a hint in the summary
* Recommend yes for brownfield too

## Decision Outcome

Chosen option: "Ask in the interview", because the user is already answering setup questions and the integration and push questions follow naturally on yes. `git-init.sh --check` names the state (`none`, `parent`, `repo`) and the recommendation; a folder inside a parent work tree names its top level and recommends using it. `git init -b main` falls back to `git init` plus `git symbolic-ref` on git older than 2.28. `npx groma-cli init` asks the same questions: outside a work tree `--git init|skip`, inside a parent work tree `--git use|init` with `use` recommended. The CLI has no stack question, so its `.gitignore` takes the `all` rows plus the rows whose manifest exists at the project root (`git-init.sh` detects them); `/groma` also passes the stacks the interview named with `--stack`. Without git on PATH, `git-init.sh --check` prints `state missing` and neither path asks a git question.

Always running `git init` lost because it acts without consent (ADR 0035). A hint lost because the user leaves the flow and the first docs gate still breaks. Brownfield yes lost because a copied codebase would get a history detached from its origin.

### Consequences

* Good, because a greenfield run ends in a repository on `main`.
* Bad, because one more interview question.

### Confirmation

`tests/scripts/git-init.bats` covers the states, the recommendations and the `-b` fallback; `cli/test/init.test.js` the CLI flags, the parent question and the manifest rows; `tests/scripts/git-init.bats` also covers git missing from PATH.
