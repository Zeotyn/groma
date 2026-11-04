Milestone: m003

## Why

groma documents what a project is (vision, architecture, data model) but not how its code is written. Agents then guess the style on every change: indentation, naming, error handling, where tests go. Without a documented style, every `opsx:apply` drifts a little further from the existing code.

## What Changes

- New mandatory doc `docs/code-style.md`. It has three sections:
  - **Enforced by tools:** a table of tool, config path, check command and fix command. It links the config files and does not copy their rules.
  - **Conventions:** rules found in the code, each tagged `EXTRACTED` or `INFERRED` with a source path.
  - **Decisions:** links to ADRs.
- New reference table `code-style-tools.md` in groma-lay-out. It lists, per stack, the formatter and linter, the config files used to detect them, the check and fix commands, the install command and the recommended default. Stack knowledge stays in the table.
- **Brownfield:** the survey detects style tools from config files, infers conventions from a code sample, and reports static drift against `.editorconfig` (indentation, line endings, final newline, trailing whitespace). It also reports when a tool is configured but its check runs in neither CI nor the scripts. No project tool is executed.
- **Greenfield**, or brownfield without any style tool: the interview recommends tools for the stack. After confirmation groma creates `.editorconfig` and the tools' own config files as new files. It records an accepted ADR for each tool choice. Dependency installs follow the existing ask-or-`install.sh` flow.
- **Existing style guides** (`CONTRIBUTING.md`, `STYLEGUIDE.md`, `docs/conventions.md` and others) fill the slot. Missing parts go into the findings report as a snippet.
- **Agents follow the style:** AGENTS.md points to `docs/code-style.md` and lists the check commands. The OpenSpec `context` gets a code-style line when groma creates the config. groma-loop runs the check commands in the tests gate and gives the reviewer `docs/code-style.md` as project rules.
- **Dogfood:** groma's own `docs/code-style.md` covers POSIX sh, shellcheck, the no-`A && B || C` rule, the Markdown table conventions and English artifacts.

## Capabilities

### New Capabilities
- `code-style`: code-style doc content, tool reference table, detection, convention inference, static drift, greenfield config generation.

### Modified Capabilities
- `docs-scaffold`: `docs/code-style.md` joins the mandatory docs tree.
- `orchestration`: interview question for style tools.
- `agent-instructions`: AGENTS.md code-style pointer and check commands.
- `review-loop`: style checks in the tests gate, `docs/code-style.md` as review rules.
- `methodology-setup`: OpenSpec `context` line for code style.

## Impact

- New: `skills/groma-lay-out/references/code-style-tools.md`, `templates/docs/code-style.md`, `templates/code-style/` (config templates); `skills/groma-survey/scripts/style-drift.sh`; `tests/scripts/style-drift.bats`; fixture updates (style configs in node-prisma, drift in python-django-stale-docs, a style guide in java-flyway).
- Changed: groma-lay-out, groma-survey, groma, groma-agents, groma-loop SKILL.md files and templates; `references/doc-slots.md`; `references/methodologies.md`; `skills/groma/references/upgrades.md` (0.3.0 row: create the doc on update); evals and assertions.
- Docs impact: `docs/architecture.md` (new script, new reference), `docs/concept.md` (style layer), `docs/glossary.md` (code style, drift), new `docs/code-style.md`, ADR for D1 and D3.
- Depends on C004: `code-style.md` lists config files as `sources`, so `docs-impact.sh` reports the doc when a config changes.
