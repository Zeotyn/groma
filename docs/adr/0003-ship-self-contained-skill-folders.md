---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/, .claude-plugin/plugin.json, .codex-plugin/plugin.json, .cursor-plugin/plugin.json, gemini-extension.json, openspec/changes/c001-groma-suite/design.md]
---

# Ship self-contained skill folders from one repository with per-agent manifests

## Context and Problem Statement

groma must install on Claude Code, Copilot, Gemini CLI, Cursor and Codex. `npx skills` installs skill folders only, so anything outside a skill folder is missing on user machines.

## Decision Drivers

* Selective installs (`npx skills add --skill groma-lay-out`) must work.
* One version for the whole suite.

## Considered Options

* One repo, one folder per skill with its own `scripts/`, `templates/`, `references/`, plus per-agent manifests
* One monolithic SKILL.md
* One repository per skill

## Decision Outcome

Chosen option: "One repo, one folder per skill", because it allows selective installs without version skew. Folder names carry the `groma-` prefix to stay unique when installed flat.

### Consequences

* Good, because every skill works on its own.
* Bad, because files shared between skills (for example `detect.sh`) are reached by sibling path and fail when the sibling is missing.

### Confirmation

`tests/structure/check.py` checks folder names, SKILL.md `name` and manifests.

## More Information

Derived by groma from existing code on 2026-11-04 (design decision D1); confirm or reject.
