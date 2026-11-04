---
name: groma-survey
description: Read-only survey of an existing repository - code map, ADR and docs harvest, stale-doc check, data model from migrations and schemas, proposed ADRs, findings report. Use for brownfield onboarding, "what is in this repo", missing or outdated docs, or when /groma finds existing code.
---

# groma-survey

Survey an existing project like a surveyor walks a site before anyone builds: measure everything, move nothing.

**Writes are additive.** Create files only at paths that do not exist yet, plus `.groma/` and `docs/_groma/`. Before every write, check the path; if it exists, record a finding instead. Pre-existing files stay byte-identical (the test suite checks this).

Paths below are relative to this skill folder unless they start with `<project>`.

## Steps

1. **Detect.** Run `sh ../groma-detect/scripts/detect.sh <project>` if groma-detect is installed, else `find` the files yourself. Done when you know the languages, manifests and history depth.

2. **Code map.** Use the discovery skill from `.groma/config.yaml` (`skills.discovery`, default graphify):
   - graphify installed: run it on `<project>` and read its report (god nodes, communities).
   - repomix chosen: `npx --yes repomix@1.18.1 --compress --output <project>/.groma/repomix.xml`, then read that file.
   - neither: read the tree, manifests and entry points; mark the code map `degraded`.
   Done when you can name the main modules, their dependencies, entry points and external systems, each with a path as evidence.

3. **ADR harvest.** Apply every row of [references/adr-sources.md](references/adr-sources.md). Done when every candidate location was checked and each ADR found has path, number, title, status, date.

4. **Docs harvest.** List every Markdown doc outside code folders (README, `docs/`, `doc/`, wiki folders, arc42 folders). Map each to a groma doc slot (vision, concept, architecture, data model, glossary, risks, ADR) using `../groma-lay-out/references/doc-slots.md` when available.

5. **Freshness.** Run `sh scripts/freshness.sh <project>` (add `--docs <dir>` for docs outside `docs/`). Every `stale` line becomes a finding with its reason (dates, or the open ADR proposal). Every `broken` line becomes a finding with the listed paths and the action "fix `sources` in frontmatter". Done when every doc from step 4 has fresh, stale, broken or unknown.

6. **Data model.** Apply [references/data-sources.md](references/data-sources.md) top-down. Draft entities and relationships with `EXTRACTED`/`INFERRED` tags and source paths; record every disagreement between levels as drift. No sources and the project has a database: offer the dump script, never connect yourself.

7. **Proposed ADRs.** When step 3 found **no** ADR anywhere, derive the decisions the code already shows: language and runtime, framework, persistence, API style, build and deployment, test approach. Write each as `<project>/docs/adr/NNNN-<kebab-title>.md` from `../groma-lay-out/templates/adr-template.md` (or MADR 4.0 from memory) with `status: proposed`, `evidence: [paths]` and "Derived by groma from existing code; confirm or reject." Numbering starts at 0003 (0001 and 0002 are the groma seed ADRs that groma-lay-out writes); when ADRs exist, propose only decisions that clearly lack one, numbered after the highest found.

8. **Report.** Fill [templates/findings.md](templates/findings.md) into `<project>/docs/_groma/findings-<YYYY-MM-DD>.md` (if taken: `-2`, `-3`, ...). Every finding has severity, evidence and one suggested action. Put proposed edits to existing files (for example a pointer line for an existing `CLAUDE.md`) under "Snippets for existing files".
   Done when the report exists and contains no `{{` placeholder.

## Severity guide

- **high**: no ADRs at all; architecture or data-model doc contradicts the code; data-model drift on a persisted field.
- **medium**: stale doc; mandatory doc missing; ADR without status; ADR proposed for too long.
- **low**: naming or formatting issues, missing frontmatter, broken `sources` in doc frontmatter.

## Hand-off

Tell the caller (or the user) the report path and the top three findings. When running standalone, suggest `groma-lay-out` next to create the missing docs from this survey.
