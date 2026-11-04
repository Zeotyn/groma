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

## Summary

| Area | Result |
|---|---|
| Project type | {{project_type}} ({{signals}}) |
| Code map | {{code_map: graphify / repomix / degraded (file tree only)}} |
| ADRs | {{adr_count}} found, {{adr_proposed}} proposed |
| Docs | {{docs_found}} found, {{docs_stale}} stale, {{docs_missing}} missing |
| Data model | {{data_model_level: highest source level used}}, {{drift_count}} drift findings |

## Findings

| # | Severity | Area | Finding | Evidence | Suggested action |
|---|---|---|---|---|---|
| 1 | {{severity}} | {{area}} | {{finding}} | {{evidence: paths, dates}} | {{action}} |

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

## Snippets for existing files

groma does not edit existing files. Add these yourself if you agree.

{{snippets: e.g. "Add `@AGENTS.md` as the first line of CLAUDE.md"}}
