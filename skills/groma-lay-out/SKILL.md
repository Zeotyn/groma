---
name: groma-lay-out
description: Creates or completes the docs/ folder - vision, concept, architecture, data model, glossary, risks, MADR 4.0 ADRs and an index - without touching existing files. Use when a project lacks docs or ADRs, when asked to set up documentation, or after groma-survey.
---

# groma-lay-out

Lay out the project's `docs/` tree: every mandatory slot filled, either by an existing file or by a new one from the templates.

**Writes are additive.** Create a file only when its path does not exist. An existing file that covers a slot fills it; link to it instead of creating a second one. Proposed edits to existing files go into the findings report (`docs/_groma/`), never into the file.

Paths are relative to this skill folder unless they start with `<project>`.

## Inputs

Use whatever is available, in this order: survey results (from groma-survey in this session or the latest `<project>/docs/_groma/findings-*.md`), interview answers, `<project>/.groma/config.yaml`, the code itself. A missing input means more `Not yet documented.` sections, never invented content.

## Steps

1. **Inventory.** List every file under `<project>/docs/` and the root-level docs. Map each to a slot with [references/doc-slots.md](references/doc-slots.md). Done when each of the 8 slots is marked *filled by <path>* or *empty*.

2. **Fill empty slots.** For each empty slot, copy the template from [templates/docs/](templates/docs/) to the groma path and resolve every placeholder (rules in doc-slots.md):
   - vision, concept, glossary: from the interview or existing README; greenfield answers go here.
   - architecture: from the survey's code map, with real paths as evidence and a Mermaid context diagram. If the diagrams skill from the config (for example archify) is installed, offer an interactive diagram in addition.
   - data-model: from the survey's data-model draft, tags kept. No persistent data: `Not applicable: <reason>`.
   - risks: high and medium survey findings that are real risks or debt.
   Set frontmatter `last_reviewed` to today, `status: draft`, `review_after_days` from `docs.review_after_days` (default 90), and `sources` to the code paths the doc describes.

3. **ADRs.** When `<project>/docs/adr/` has no `0001-*` or `0002-*` and no ADR exists anywhere else, create `0001-record-architecture-decisions.md` and `0002-adopt-groma-docs-structure.md` from `templates/docs/adr/`. When ADRs exist elsewhere, keep them there and number new ones after the highest found. Write `<project>/docs/adr/README.md` if absent, listing **every** ADR (groma's, proposed ones from the survey, and found ones with their path).

4. **Optional docs.** Create each slot listed in `docs.optional` from `templates/docs/optional/` (additive, same rules).

5. **Index.** If `<project>/docs/README.md` is absent, write it from the template: one row per slot pointing at the file that fills it (existing or new), plus one row per other doc found. If it exists, put the missing rows into the findings report as a snippet.

6. **Writing quality.** If `anti-ai-slop-writing` is listed under `skills.writing` and installed, apply its rules to every prose section you wrote.

7. **Verify.** Run `grep -rn "{{" <every file you created>`; it must print nothing. Done when every slot is filled and the list of created files is ready for the caller.

## Report

List created files, slots filled by existing files, and snippets you could not apply because the target existed.
