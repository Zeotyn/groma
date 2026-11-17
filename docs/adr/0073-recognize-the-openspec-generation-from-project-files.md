---
status: proposed
date: 2026-11-17
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/methodologies.yaml, skills/groma-methodology/scripts/next.sh, tests/scripts/next.bats]
origin: f009-openspec-2#D1
---

# Recognize the OpenSpec generation from project files

## Context and Problem Statement

OpenSpec 2.0 replaced the `/opsx:<step>` slash commands with skills called as `/openspec-apply-change`, `/openspec-verify-change` and so on, kept in `.agents/skills/`. groma printed `/opsx:` commands in the next action, so a project that ran `openspec update` got commands that no longer exist, while projects still on 1.x need the old form. How does groma know which form a project needs?

## Decision Drivers

* `next.sh` runs on every prompt and has a 300 ms budget, so no process call
* The answer must follow what the project has installed, also after a teammate upgrades
* Stack and tool knowledge belongs in data, not in script logic

## Considered Options

* Marker paths in the project, listed as recipe data
* `openspec --version`
* A `methodology_version` key in `.groma/config.yaml`

## Decision Outcome

Chosen option: "Marker paths in the project, listed as recipe data", because it needs no process call and follows the files the project actually has. The `openspec` recipe in `methodologies.yaml` has a `generations` list; each entry names `markers` (paths, `*` globs) and a `command` pattern with `{step}`. The first entry with a marker in the project wins: an `opsx` command folder of any agent means 1.x (`/opsx:{step}`), even when 2.x skills sit beside it, because the old commands still work until `openspec update` removes them; otherwise an `openspec-*` skill folder means the skill form (`/openspec-{step}-change`). The skills carry the same names in 1.x and 2.x (checked with `openspec init` of 1.16.0, 2.0.0 and 2.1.0), so the skill form is also right for a 1.x install without commands, such as Codex: groma tells command forms apart, not version numbers. No marker, no command. `touches` lists `.agents/skills/openspec-*`, so a 2.x install counts as OpenSpec's own files. The next-action cache needs no new key: `openspec update` changes tracked files, so `HEAD` or `git status --porcelain` change and the cache is dropped.

`openspec --version` lost because a process call per prompt breaks the budget and the global CLI version says nothing about the project. A config key lost because it goes stale the moment a teammate runs `openspec update`.

### Consequences

* Good, because a third generation is one more recipe entry, not a code change.
* Good, because a half-finished upgrade keeps working commands.
* Bad, because the step names live in the pattern: if OpenSpec renames its skills, the recipe entry changes.
* Bad, because a project that gitignores its agent folders keeps the old form in the cached line until the next commit.
* Neutral, because the init pin for new projects stays at OpenSpec 1.16.0; moving it is a separate change.

### Confirmation

`tests/scripts/next.bats` covers 1.x commands, skills only (also the 1.16.0 Codex layout), both and no markers; `tests/structure/check.py` checks that every `generations` entry has markers and a `command` with `{step}`.
