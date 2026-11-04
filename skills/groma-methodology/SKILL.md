---
name: groma-methodology
description: Initializes a spec methodology (OpenSpec, Spec Kit, BMAD, GSD) non-interactively, links it to docs/, and sets up the change naming convention m/c/f/s/r/d with next-id, check and roadmap scripts. Use during /groma, when choosing or adding a methodology, or when creating, naming or checking changes and milestones.
---

# groma-methodology

Set up one spec methodology and the change naming convention. `docs/` stays the product truth; the methodology holds change work and points at `docs/`.

## Steps

1. **Choose.** Use `methodology` from `<project>/.groma/config.yaml`. Not set: ask, recommended first:
   ```
   Spec methodology?
     ▸ openspec (recommended): light, change folders, built for existing code
       spec-kit: constitution and phase gates, good for teams
       bmad: full agile roles (PO, architect, ...)
       gsd: phases with fresh subagents per step
       none
   ```

2. **Initialize.** Read the chosen recipe in [methodologies.yaml](methodologies.yaml) and apply it as [references/methodologies.md](references/methodologies.md) describes: skip when already present, check prerequisites (`sh ../groma/scripts/check-prereqs.sh` when available), ask before the init touches existing files, run the init command. On missing tools, refusal or failure: add the command to `<project>/.groma/install.sh`, mark `steps.methodology: pending` in the config, and continue.
   Done when the methodology folder exists or its command is pending in `.groma/install.sh`.

3. **Link to docs.** Append the recipe's `docs_link.append` to `docs_link.file`, only when this run created that file. For files that existed before, put the text into the findings report as a snippet.

4. **Convention.** Write `conventions.changes` into the config if missing (defaults in [references/conventions.md](references/conventions.md)). If the changes folder already holds changes, write their names to `<project>/.groma/conventions-baseline.txt` (only if that file is absent). Run `sh scripts/check-conventions.sh --root <project>`; it must print `conventions: ok`.

5. **Report.** Methodology state (initialized, already present, pending), where changes live, and how to create the next one:
   ```
   Next change id: sh <this skill>/scripts/next-change-id.sh c --root .
   ```

## Creating a change later

When the user asks for a new change, fix or milestone in a groma project: get the id from `scripts/next-change-id.sh <type>`, name it `<id>-<slug>`, add `Milestone: mNNN` as first line of `proposal.md` when it belongs to an active milestone, and run `scripts/roadmap.sh --root <project>` after creating or archiving a milestone child.
