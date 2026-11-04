## 1. Repository foundation

- [x] 1.1 Add `LICENSE` (MIT), `README.md` skeleton with install matrix placeholders, `CHANGELOG.md` (Keep a Changelog, `Unreleased`), `CONTRIBUTING.md` skeleton
- [x] 1.2 Add root `AGENTS.md` for contributors and `CLAUDE.md` containing `@AGENTS.md`
- [x] 1.3 Fill `openspec/config.yaml` `context` with project conventions (English artifacts, POSIX sh scripts, skills as Markdown, no DB access)
- [x] 1.4 Create the folder layout from design D1 (`skills/`, `scripts/`, `tests/`)

## 2. Test harness first (levels 1–2)

- [x] 2.1 Add `tests/structure/` checks: SKILL.md frontmatter (`name` = folder, description length), Markdown link check
- [x] 2.2 Add catalog schema and validator for `skills/groma-skills/catalog.yaml`
- [x] 2.3 Add version-consistency check across all manifests and `CHANGELOG.md`
- [x] 2.4 Set up `bats-core` with a sample test and a `make test` / `scripts/test.sh` entry point
- [x] 2.5 Add GitHub Actions workflow: levels 1–2 on every PR, matrix ubuntu + macos

## 3. Fixtures and invariant (level 3)

- [x] 3.1 Write `tests/fixtures/generate.sh` that builds fixtures with deterministic git history (fixed dates, authors)
- [x] 3.2 Create fixtures: `empty`, `node-prisma`, `java-flyway`, `python-django-stale-docs` (docs 2 years older than code), `go-no-db`
- [x] 3.3 Add `tests/invariant/checksum.sh`: snapshot SHA-256 of all files, compare after a run, name changed files
- [x] 3.4 Add bats tests for the invariant script itself (detects change, passes on additions only)

## 4. Shared scripts

- [x] 4.1 `skills/groma-detect/scripts/detect.sh`: emit greenfield/brownfield plus signals as key=value lines, driven by the table in `references/signals.md`
- [x] 4.2 `skills/groma-survey/scripts/freshness.sh`: report stale docs via frontmatter dates and git ages of `sources`
- [x] 4.3 `skills/groma/scripts/check-prereqs.sh`: report node/npx/git/uv presence and versions
- [x] 4.4 `skills/groma-survey/scripts/dump-schema.sh`: user-run, schema-only dump for postgres/mysql/sqlite into `.groma/schema/`, never prints credentials
- [x] 4.5 `skills/groma-methodology/scripts/next-change-id.sh <type>`: next per-type id from active + archived changes
- [x] 4.6 `skills/groma-methodology/scripts/check-conventions.sh`: report non-conforming names and duplicate ids, suggest fixes
- [x] 4.7 `skills/groma-methodology/scripts/roadmap.sh`: regenerate `docs/roadmap.md` from milestone and child proposals
- [x] 4.8 bats tests for 4.1–4.7 against fixtures (incl. archive prefix, collision, custom type)

## 5. Templates

- [x] 5.1 `skills/groma-lay-out/templates/`: doc templates with freshness frontmatter: README (index), vision, concept, architecture (C4 context/container), data-model (conceptual/logical, Mermaid erDiagram, EXTRACTED/INFERRED legend), glossary, risks
- [x] 5.2 `skills/groma-lay-out/templates/adr/`: MADR 4.0 ADR template, seed ADRs 0001 and 0002, ADR index template
- [x] 5.3 `skills/groma-agents/templates/`: agent pointer templates: AGENTS.md, CLAUDE.md, GEMINI.md, copilot-instructions.md, cursor `groma.mdc`
- [x] 5.4 `skills/groma/templates/config.yaml`: `.groma/config.yaml` template (schema 1, commented) and its validator

## 6. Skills

- [x] 6.1 `skills/groma-detect/`: SKILL.md + `references/signals.md`; uses `scripts/detect.sh`; supports user override
- [x] 6.2 `skills/groma-lay-out/`: create/complete docs tree, never overwrite, ADR numbering continuation, docs index; standalone usable
- [x] 6.3 `skills/groma-survey/`: read-only discovery: code map via graphify with fallback, ADR harvest (`references/adr-sources.md`), doc harvest, freshness, data-model extraction (`references/data-sources.md`), retroactive ADRs `proposed`, findings report
- [x] 6.4 `skills/groma-skills/catalog.yaml`: initial categories and entries (design, writing, pragmatism, workflow, diagrams, discovery) with pinned sources
- [x] 6.5 `skills/groma-skills/`: interview by category (conditional, multi-select), install per agent (plugin → `npx skills`), `.groma/install.sh` fallback, apply writing skills to generated docs
- [x] 6.6 `skills/groma-methodology/`: non-interactive init for openspec, spec-kit, bmad, gsd; workflow layer; link to `docs/`; prerequisite handling
- [x] 6.7a Convention support: `conventions.changes` defaults in config template, convention text for AGENTS.md and OpenSpec `rules`, mapping notes for Spec Kit/BMAD/GSD, milestone and roadmap templates
- [x] 6.7 `skills/groma-agents/`: AGENTS.md + pointer files per configured agent; snippets for existing files
- [x] 6.8 `skills/groma/`: orchestrator with 8-step sequence, step announcements, interview with defaults, resume, update mode, graceful degradation, final summary

## 7. Distribution

- [x] 7.1 `.claude-plugin/plugin.json` and `marketplace.json`; pass `claude plugin validate`
- [x] 7.2 `.codex-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `gemini-extension.json` (best effort, schema-checked)
- [x] 7.3 `install.sh` / `uninstall.sh`: detect agents, link/copy, `--dry-run`, `--ref`, idempotent, never clobber; bats tests
- [x] 7.4 Verify `npx skills add <local path> --skill groma-lay-out` installs a single skill that runs standalone

## 8. Evals (level 4)

- [x] 8.1 Eval runner: headless `claude -p` on a fresh copy of each fixture with scripted interview answers
- [x] 8.2 Assertions per fixture: classification, mandatory docs, ADRs (seed or proposed), stale-doc findings, data-model tags, invariant check
- [x] 8.3 Nightly + `eval`-label GitHub Actions workflow with API key secret
- [x] 8.4 Manual Copilot test protocol (checklist in `tests/manual/copilot.md`), run once before release

## 9. Release v0.1.0

- [x] 9.1 Complete README install matrix (Claude, Copilot tested; Codex, Gemini, Cursor best effort) and CONTRIBUTING (add catalog entry, add detection pattern, add fixture)
- [x] 9.2 Run all test levels green and record C001 in CHANGELOG `Unreleased` (tagging `v0.1.0` is M001 task 2.3, because C002 is part of the same release)
- [ ] 9.3 Dogfood: run `/groma` update mode on this repository itself and fix findings
