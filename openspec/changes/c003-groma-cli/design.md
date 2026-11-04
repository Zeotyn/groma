## Context

See proposal.md. OpenSpec is the model: its CLI carries skill templates, `openspec init` writes them into each tool's project folder with `metadata.generatedBy: "<cli version>"`, and `openspec update` refreshes them (verified on this repository with OpenSpec 1.8.0). groma's skills are already self-contained (scripts, templates, references inside each skill folder, ADR 0003), and all setup knowledge sits in Markdown references today (`groma-methodology/references/methodologies.md`, `groma-skills/references/install.md`).

## Goals / Non-Goals

**Goals:**
- `npx groma init` sets up a project with zero agent involvement and zero agent permissions.
- One source of truth for install recipes, shared by CLI and skills.
- Skills keep working without the CLI (plugin, `npx skills`, `install.sh`).

**Non-Goals:**
- Porting skill logic (survey, docs, loop) to Node; the CLI never needs an LLM.
- A global `groma` install requirement; `npx` is the documented path.
- Supporting Node < 22.

## Decisions

### D1 Hybrid: the CLI installs, the skills stay self-contained
The npm package contains `skills/` verbatim and copies whole skill folders. Skills keep calling their own `scripts/*.sh`, not the CLI, so a plugin or `npx skills` install behaves the same as a CLI install. *Alternative:* OpenSpec's full model (skills call `npx groma …`), rejected: it would port the tested sh logic to Node and make every skill depend on Node.

### D2 Node, ESM, one runtime dependency
`bin/groma.js` and `cli/*.js`, Node ≥ 22, prompts via `node:readline/promises`, tests via `node --test`. The only runtime dependency is `yaml` (pinned) for catalog, recipes and config. *Alternatives:* `@clack/prompts` for nicer prompts (rejected for now: second dependency, readline is enough); JSON data files instead of YAML (rejected: catalog and config are hand-edited).

### D3 Recipe data files
- `skills/groma-methodology/methodologies.yaml`: per methodology `detect`, `requires`, `init` (command template with `{agents}`), `agent_ids` map, `touches`, `interactive`, `docs_link`.
- `skills/groma/agents.yaml`: per agent `skills_dir` (claude `.claude/skills`, copilot `.github/skills`, gemini `.gemini/skills`, cursor `.cursor/skills`, codex `.agents/skills`), `home_marker`, `npx_skills_id`, instruction file.
- `skills/groma-skills/catalog.yaml`: unchanged schema plus nothing new.
The Markdown references keep the explanations and point to the data files; command lines no longer live in prose. Skills read the YAML with the agent's own tools.

### D4 Generated-file ownership
Every materialized SKILL.md gets `metadata.generatedBy: groma@<version>`; `.groma/generated.json` maps each generated path to its SHA-256. Ownership rule extends the additive rule: a file is groma's to replace only if it is listed there **and** its current hash matches. Everything else is user-owned. Copies are committed with the project (team gets the same version), like OpenSpec's.

### D5 Plugin coexistence
`init` runs `claude plugin list` when `claude` is an agent; if `groma` is listed, it offers to skip Claude materialization (default skip) and records `agents_via_plugin` in the config. The validator accepts this key.

### D6 Step state shared with `/groma`
The CLI writes `steps.config|methodology|skills` and `initialized_with`; the orchestrator already resumes from `steps` (C001), so the only orchestrator change is skipping the setup questions and recommending the CLI for pending installs.

### D7 Testing
- `node --test` unit tests for flag parsing, answer resolution (flags > TTY answers > recommended), recipe rendering, materialization, ownership/update rules.
- bats end-to-end tests that run `node bin/groma.js init --yes --print` on generated fixtures with stubbed `npx`, `claude`, `openspec` on PATH, asserting files, config, `install.sh` content and the never-overwrite invariant.
- `npm pack --dry-run` check in CI that the package contains `bin/`, `cli/`, `skills/` and nothing from `tests/` or `openspec/`.

## Risks / Trade-offs

- [Two install paths drift apart] → shared recipe files; a test renders the same config through CLI `--print` and compares with the documented commands.
- [Copies in projects go stale] → `groma status`/`doctor` report the generated version against the CLI's; `/groma` update mode mentions `npx groma update`.
- [Users edit generated skills] → hash check keeps their edits; `--force` is explicit.
- [npm name squatting before publish] → publish a 0.2.0 release promptly; `@zeotyn/groma` is the fallback name.
- [Windows paths] → Node `path` APIs; sh scripts inside skills still need a POSIX shell on Windows (documented).

## Migration Plan

Projects set up with 0.1 (agent-driven) keep working: `npx groma update` adopts them by writing `.groma/generated.json` only for files it creates; existing skill copies stay user-owned.

## Open Questions

- Whether `groma init` should also create `docs/` skeleton files without content (deferred: docs content needs the agent; keep init to setup only).
