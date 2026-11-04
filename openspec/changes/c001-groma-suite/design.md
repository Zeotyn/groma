## Context

The repository is empty apart from OpenSpec (initialized for Claude Code and GitHub Copilot). See proposal.md for motivation. The suite is open source and must work across Claude Code, GitHub Copilot, Gemini CLI, Cursor and Codex. Maintainers can only test Claude Code and Copilot, so everything else relies on shared standards (SKILL.md, AGENTS.md, `npx skills`).

Skills are Markdown instructions executed by an agent. The agent already reads any language. That shapes most decisions below: the suite ships **knowledge and procedure**, not parsers.

## Goals / Non-Goals

**Goals:**
- One `/groma` run takes an empty or existing folder to a documented, configured project.
- Works for any language or stack without stack-specific code.
- Re-running is safe and acts as an update.
- Easy to contribute: most extensions are a table row or a catalog entry.

**Non-Goals:**
- Connecting to databases or other live systems.
- Rewriting, moving or deleting existing project files.
- Re-implementing what methodologies or third-party skills already do (we call their installers).
- Hosting a registry of skills; the catalog only references upstream repos.

## Decisions

### D1 Repository layout: single source of truth with per-agent manifests
```
groma/
├─ .claude-plugin/{plugin.json, marketplace.json}   # Claude Code + Copilot CLI
├─ .codex-plugin/plugin.json
├─ .cursor-plugin/plugin.json
├─ gemini-extension.json
├─ skills/
│  ├─ groma/                 # orchestrator
│  ├─ groma-detect/
│  ├─ groma-survey/          # brownfield discovery (read-only)
│  ├─ groma-lay-out/         # docs scaffold
│  ├─ groma-methodology/
│  ├─ groma-skills/          # catalog selection + install
│  └─ groma-agents/          # AGENTS.md + pointer files
├─ scripts/                  # repo development only (test.sh), not shipped
├─ install.sh, uninstall.sh
└─ tests/
```
Runtime scripts, templates and the catalog live **inside the skill that uses them** (`skills/<skill>/scripts/`, `skills/<skill>/templates/`, `skills/groma-skills/catalog.yaml`), because `npx skills` installs skill folders only; repo-level `scripts/`, `templates/` or `catalog/` folders would be missing on user machines. Scripts are referenced relative to the SKILL.md. A skill never calls another skill's scripts directly, so selective installs keep working.
Skill folder names carry the `groma-` prefix so they stay unique when installed flat into `~/.agents/skills` by `npx skills`. Under the Claude plugin they appear namespaced (`/groma:groma-survey`), which is acceptable.
*Alternatives:* one monolithic SKILL.md was rejected because it is too large for context and cannot be installed selectively. Separate repos per skill were rejected because of the version-skew burden.

### D2 Knowledge as data tables, not code
Stack-specific knowledge lives in `references/*.md` tables inside the skills: data-model sources, ADR locations, doc locations, greenfield signals. The agent applies them. A new stack means a PR with a new row.
*Alternative:* per-language extractor scripts were rejected because they cannot cover "all stacks" and need a test matrix per language.

### D3 Data-model source hierarchy, no live DB
Priority: migrations → schema files → ORM entities → API contracts → graph inference. Optional user-run `skills/groma-survey/scripts/dump-schema.sh` writes a schema-only dump to `.groma/schema/`; the agent reads the file only. The doc covers the conceptual and logical model (Mermaid `erDiagram`); the physical model is referenced, not copied. Statements are tagged `EXTRACTED` or `INFERRED`.
*Alternative:* a direct DB connection was rejected because of credentials in the agent context, network access and production risk.

### D4 Read-only brownfield with additive writes
Discovery writes only to paths that do not yet exist plus `.groma/` and `docs/_groma/`. A pre-write check refuses to overwrite. This is proven by the checksum invariant in tests (D9).

### D5 Docs conventions
- arc42-aligned split files; MADR 4.0 ADRs in `docs/adr/NNNN-kebab-title.md`; seed ADRs 0001 (record decisions) and 0002 (adopt groma docs structure).
- Frontmatter on every generated doc: `title, status, last_reviewed, review_after_days, owner, sources`.
- Staleness = `last_reviewed` older than `review_after_days` **or** newest git commit touching any `sources` path is newer than the newest commit touching the doc. Implemented in `skills/groma-survey/scripts/freshness.sh` (git only, POSIX sh).
- `docs/` is the product truth; methodology folders (`openspec/`, `specs/`, `.specify/`) hold change work and reference `docs/`.

### D6 Third-party installation via native installers
The catalog entry declares, per entry, `source`, an optional `claude_plugin` (`name@marketplace`) and an optional `post_install` command. Install order: Claude plugin when the agent is Claude and a plugin exists, otherwise `npx skills add <source> --skill … -a <agents> -y` (project scope). Methodologies use their own CLIs non-interactively (`openspec init --tools`, `specify init --here --non-interactive`, …).
Agents that may not execute installs get a generated `.groma/install.sh` listing the exact commands for the user to run.

### D7 Config and versioning
`.groma/config.yaml` with `schema: 1` and `initialized_with: groma@<version>`. The suite follows SemVer; config schema changes bump `schema` and ship a migration note that the orchestrator prints. Updates: `npx skills update`, `claude plugin update`, or `install.sh --ref vX.Y.Z`.

### D8 Agent instructions
`AGENTS.md` is canonical and short (commands, conventions, pointer to `docs/README.md`). `CLAUDE.md` and `GEMINI.md` contain `@AGENTS.md`; `.github/copilot-instructions.md` and `.cursor/rules/groma.mdc` (`alwaysApply: true`) contain a plain pointer. Existing files are never edited: if one exists without a pointer, a suggested snippet goes into the findings report.

### D10 Change naming convention
Format `<type><NNN>-<slug>`, lowercase, because OpenSpec rejects uppercase change names (verified with OpenSpec 1.8.0: `M1-user-login` → "Change name must be lowercase"). Three digits keep lexical order equal to numeric order (`c010` after `c009`). Counters are per type and scan `openspec/changes/` plus `archive/`, stripping the `YYYY-MM-DD-` archive prefix.
The milestone link lives in the child's `proposal.md` as a `Milestone: mNNN` line, not in `.openspec.yaml`: OpenSpec tolerates extra keys there today, but that is not a documented contract, and the proposal line also works for other methodologies. `skills/groma-methodology/scripts/next-change-id.sh` computes the next id; `check-conventions.sh` next to it reports violations and duplicates; `roadmap.sh` regenerates `docs/roadmap.md` from milestone and child proposals.
Mapping for other methodologies: Spec Kit feature folders use the same id as prefix (`specs/c004-export-csv/`); BMAD epic ↔ `m`, story ↔ `c`/`f`; GSD phase ↔ `m`. These mappings are documented, not enforced.
*Alternatives:* a global counter across types (rejected: type ranges become unreadable); date-based ids like log4brains (rejected: the user wants type letters and short ids); a strict hierarchy with folders per milestone (rejected: OpenSpec has no nested changes).

### D11 Third-party installers and pre-existing files
groma's own writes are additive. Third-party installers it runs on the user's behalf are not: `npx skills add` writes `skills-lock.json`, `claude plugin install --scope project` edits `.claude/settings.json`, methodology CLIs write their folders (Spec Kit's `--force` even overwrites). Rule: before running an installer, groma lists the files it is known to touch (reference table in `groma-skills/references/install.md` and `groma-methodology/references/methodologies.md`). If any of them already exists, groma asks the user once for that installer; on "no" it writes the command to `.groma/install.sh` instead. groma never passes overwrite flags such as `specify init --force`.
Pinned installs use `npx --yes skills@<version> add https://github.com/<source>/tree/<ref>` (verified with skills 1.7.6: installs into `.agents/skills/` and links `.claude/skills/`).

### D9 Testing strategy
| Level | Tooling | When |
|---|---|---|
| 1 Structure | frontmatter lint, `claude plugin validate`, catalog schema check, link check | every PR |
| 2 Scripts | `bats-core` for `install.sh`, `freshness.sh`, `dump-schema.sh`, `detect` helpers | every PR |
| 3 Invariant | run discovery on fixtures, compare SHA-256 of all pre-existing files before/after | every PR (scripted parts) + evals |
| 4 Evals | headless agent runs (`claude -p`) on fixtures with assertions on produced files | nightly / `eval` label |

Fixtures: `empty`, `node-prisma`, `java-flyway`, `python-django-stale-docs`, `go-no-db`. Fixture git history is generated by a setup script, so stale-doc dates are deterministic.

## Risks / Trade-offs

- [Upstream skills rename or vanish] → catalog entries pin a repo ref; a weekly CI job checks that sources resolve.
- [Agent ignores "never overwrite"] → refusal rule in every writing skill + level-3 invariant in evals.
- [Gemini/Cursor/Codex manifests drift because untested] → mark as best effort in README; level-1 schema checks for all manifests.
- [Third-party installers become interactive] → wrap each call, detect a non-zero exit or a prompt, and fall back to printing the command.
- [Eval cost] → evals only nightly or on label; small fixtures.
- [Name collision `groma` in a marketplace] → plugin name `groma`, skill prefix `groma-`; checked on npm/GitHub on 2026-11-03.

## Migration Plan

Greenfield repository; no migration. Release `v0.1.0` after Claude Code + Copilot evals pass on all fixtures. Rollback = users pin the previous tag.

## Open Questions

- GitHub owner/org for the public repo (affects URLs in manifests only).
- Whether to publish an npm wrapper (`npx groma`) later; `npx skills` covers installation for now.
