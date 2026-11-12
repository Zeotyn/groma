---
status: accepted
date: 2026-11-11
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-lay-out/SKILL.md, skills/groma-lay-out/templates/code-style/, skills/groma-skills/references/install.md]
origin: c005-code-style#D5
---

# Write style configs to new paths and ask before installs

## Context and Problem Statement

After the interview confirms style tools, groma has to create their configs and make the tools available. Config files are new files; dependency installs (`npm i -D prettier`, `uv add --dev ruff`) rewrite manifests and lockfiles. What may groma write, and when?

## Considered Options

* Write `.editorconfig` and the template configs only when the target path does not exist; record one ADR per chosen tool with `status: accepted`, because the user decided in the interview; route installs through the consent flow of groma-skills (run after a yes, otherwise append to `.groma/install.sh`); brownfield default is "document only"
* Always write the configs, also in brownfield
* Never create configs; document only

## Decision Outcome

Chosen option: "new paths, accepted ADRs, consent for installs", because it keeps ADR 0006 (additive writes) intact while still giving a greenfield project a working setup. Adding a linter to years of existing code causes a flood of failures nobody asked for, so brownfield recommends "document only". Never creating configs was rejected because the user asked for the setup in the interview. Chosen templates that share a target file name (`.editorconfig` from EditorConfig and shfmt) become one new file.

### Consequences

* Good, because pre-existing files stay byte-identical; the invariant test still holds.
* Good, because the tool decisions are on record from day one.
* Bad, because a tool inside an existing build file (Spotless) can only be offered as a snippet.

### Confirmation

`tests/evals/assert.sh` on the `empty` fixture: `.editorconfig`, `.prettierrc.json` and `eslint.config.js` exist, the ADRs are accepted and the install command is in `.groma/install.sh`; on node-prisma no `.editorconfig` is created.

## More Information

From design decision D5 of c005-code-style. Related: ADR 0006, ADR 0033.
