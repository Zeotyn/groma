---
title: groma survey findings {{today}}
status: current
last_reviewed: {{today}}
review_after_days: 30
owner: groma
sources: []
generated_by: groma-survey
---

# Survey findings, {{today}}

Read-only survey of `{{project_name}}`. No pre-existing file was changed. Severity: **high** blocks reliable work, **medium** should be fixed soon, **low** is cleanup.

## Hand-off

{{handoff: 1 to 10 lines, the same lines the survey returns to its caller: counts per severity, the top three findings, what groma-lay-out should know (data model source, existing docs to keep, proposed ADRs)}}

## Summary

| Area | Result |
|---|---|
| Project type | {{project_type}} ({{signals}}) |
| Code map | {{code_map: graphify / repomix / degraded (file tree only)}} |
| ADRs | {{adr_count}} found (highest number {{adr_highest}}), {{adr_proposed}} proposed |
| Docs | {{docs_found}} found, {{docs_stale}} stale, {{docs_broken}} broken, {{docs_missing}} missing |
| Data model | {{data_model_level: highest source level used}}, {{drift_count}} drift findings |
| Code style | {{style_tools}} tools found, {{style_drift}} editorconfig drift, {{style_unchecked}} unchecked |

## Survey scope

Files opened per category after the code map, against the cap of groma-survey's read budget (code map 15, ADRs 50, docs 30, data model: schema and model files uncapped and migrations 20, code style 10 per top-level source folder). A `capped` category stopped at its cap; what was left unread is a finding (`medium` for the data model, else `low`).

| Category | Files read | Cap | Capped |
|---|---|---|---|
| {{category: code map / ADRs / docs / data model / code style}} | {{files_read}} | {{cap}} | {{capped: yes / no}} |

## Findings

| # | Severity | Area | Finding | Evidence | Suggested action |
|---|---|---|---|---|---|
| 1 | {{severity}} | {{area}} | {{finding}} | {{evidence: paths, dates}} | {{action: for broken sources "fix `sources` in frontmatter"}} |

## ADRs found

| ADR | Title | Status | Path |
|---|---|---|---|

## Proposed ADRs (status: proposed)

| ADR | Decision | Evidence |
|---|---|---|

## Docs found

| Path | Maps to | Freshness |
|---|---|---|

## Data model draft

{{data_model: entities, relationships and tags, ready to be used for docs/data-model.md}}

## Code style draft

Ready for `docs/code-style.md` (or, when an existing style guide fills the slot, as a snippet below).

| Tool | Config | Check | Fix |
|---|---|---|---|
| {{tool}} | {{config_path}} | `{{check_command}}` | `{{fix_command}}` |

{{conventions: one line each, tagged EXTRACTED or INFERRED with paths; "No consistent pattern found." per area without one}}

## Snippets for existing files

groma does not edit existing files. Add these yourself if you agree.

{{snippets: e.g. "Add `@AGENTS.md` as the first line of CLAUDE.md"}}
