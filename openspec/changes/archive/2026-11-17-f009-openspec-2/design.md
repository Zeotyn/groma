## Context

See proposal.md for why. Today `next.sh` sets `opsx=1` whenever the changes folder is `openspec/changes` and prints `/opsx:verify` and `/opsx:apply`. `methodologies.yaml` pins `@fission-ai/openspec@1.16.0` for init and lists only 1.x paths under `touches`. OpenSpec 2.0 keeps the workflows and the `openspec/` layout; only the command entry points and the skill folder moved. The skills keep their 1.x names (`openspec-apply-change`, `openspec-verify-change`, `openspec-archive-change`, `openspec-propose`; checked with `openspec init` of 1.16.0, 2.0.0 and 2.1.0), and 1.16.0 for Codex already writes only those skills. Codex calls skills with `$openspec-apply-change`, every other agent with `/openspec-apply-change`.

## Goals / Non-Goals

**Goals:**
- Correct commands for 1.x and 2.x projects, with no process call, inside the 300 ms budget of `next.sh`.
- One place to add a third generation later.

**Non-Goals:**
- Moving new projects to OpenSpec 2.x (init pin stays 1.16.0).
- Upgrading this repository to OpenSpec 2.x.
- Codex-specific `$` prefix in the next action (the status line and hooks are Claude Code only today).

## Decisions

### D1: Recognize the generation from project files
`next.sh` and the skills look for marker paths in the project: any `opsx` command folder of a configured agent (`.claude/commands/opsx/`, `.github/prompts/opsx-*`, `.gemini/commands/opsx/`, `.cursor/commands/opsx-*`) means 1.x; otherwise any `openspec-*` skill folder (`.agents/skills/`, `.claude/skills/`, `.github/skills/`) means the skill form `/openspec-<step>-change`, right for 2.x and for a 1.x install without commands alike; otherwise the generation is unknown and no slash command is printed. Both present means 1.x, because the old commands still work until `openspec update` removes them.
Alternatives: `openspec --version` (a process call per prompt breaks the 300 ms budget, and the global CLI version says nothing about what the project has installed); a `methodology_version` key in `.groma/config.yaml` (goes stale the moment a teammate runs `openspec update`).

#### Part of D1: marker paths and command forms are recipe data
D2 and D3 of the first draft are parts of D1, recorded together in ADR 0073. `methodologies.yaml` gets, under `openspec`, a `generations` list: each entry has `markers` (paths or globs) and `command` (a pattern such as `/opsx:{step}` or `/openspec-{step}-change`). `next.sh` reads it with a few lines of awk, no YAML library; the skill pattern covers `apply`, `verify` and `archive`; the propose skill (`openspec-propose`) is named separately where a text needs it. `touches` adds `.agents/skills/openspec-*`.
Alternatives: hard-code both forms in `next.sh` (stack knowledge in script logic, against the reference-table rule); a separate reference table (a second file to keep in sync with the recipe).

#### Part of D1: the cache needs no new key
The next-action cache is keyed on `HEAD`, `git status --porcelain` and the refs. `openspec update` changes tracked files, so the porcelain output or `HEAD` changes and the cache is invalidated. No marker check runs on a cache hit.
Alternatives: add the marker paths' mtimes to the key (extra stat calls on every prompt for a case the porcelain already covers).

## Risks / Trade-offs

- [Marker folders ignored by git] → a project that gitignores `.claude/` changes generation without a porcelain change; the cache shows the old form until the next commit. Acceptable: the old command is one release behind, not broken data.
- [OpenSpec renames skills again] → only the recipe data changes (D1).
- [Init still pins 1.16.0] → new projects start on 1.x and get `/opsx:` commands, which are correct for them.

## Migration Plan

No migration. Existing 1.x projects see no change; 2.x projects get correct commands after `npx groma-cli update` or the next skill copy refresh.
