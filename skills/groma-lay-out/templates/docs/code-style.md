---
title: Code style
status: draft
last_reviewed: {{today}}
review_after_days: 90
owner: {{owner}}
sources: [{{sources: the tool config files and the sampled source folders, e.g. .editorconfig, .prettierrc, src/}}]
---

# Code style

How code in this project is written. Agents read this before writing code and run the check commands after each task. Rules that a tool enforces live in that tool's config file; this doc links the file and does not restate its rules.

## Enforced by tools

| Tool | Config | Check | Fix |
|---|---|---|---|
| {{tool}} | [{{config_path}}]({{config_link: path relative to this doc, e.g. ../.prettierrc}}) | `{{check_command}}` | `{{fix_command}}` |

{{tools_note: when no tool is configured, replace the table with "None. Decided in the interview on <date>." (greenfield) or "None found." (brownfield)}}

## Conventions

One rule per line. `EXTRACTED` comes from configuration, `INFERRED` from a sample of the code; every line names at least one file, with a line number where it shows a specific construct. Areas without a clear pattern say "No consistent pattern found."

- Files and symbols: {{naming: e.g. "kebab-case files, PascalCase classes, camelCase functions" (INFERRED, src/users/user-service.ts, src/orders/order-service.ts)}}
- Tests: {{tests: e.g. "Tests next to code as `*.spec.ts`" (INFERRED, src/users/user-service.spec.ts, src/orders/order-service.spec.ts) or "`testMatch` in jest.config.js" (EXTRACTED, jest.config.js)}}
- Imports: {{imports: e.g. "absolute imports from `src/`, external packages first" (INFERRED, src/app.ts:1-6)}}
- Error handling: {{errors: e.g. "domain errors extend `AppError`; handlers return `Result`" (INFERRED, src/errors.ts:4, src/users/handler.ts:18)}}
- {{more: further conventions found, at most 12 lines in total; greenfield: "Not yet documented."}}

## Decisions

- {{decisions: one link per style ADR, e.g. [ADR NNNN: Use Prettier for formatting](adr/{{nnnn}}-use-prettier-for-formatting.md); none: "No style decisions recorded yet."}}
