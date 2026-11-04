## Context

groma covers what a project is, not how its code is written. Style knowledge sits in three layers. Tool configs (`.editorconfig`, `.prettierrc`, `ruff.toml`) are already the source of truth for what they enforce. Conventions (naming, test placement, error handling) are written nowhere. Decisions (which tool) belong in ADRs. Agents during `opsx:apply` see only what AGENTS.md and the methodology's context point them to. Constraints: additive writes (ADR 0006), stack knowledge in tables (ADR 0004), no project tool runs during the read-only survey, POSIX sh scripts (ADR 0005). C004 provides `sources`-based docs impact; this change relies on it.

## Goals / Non-Goals

**Goals:**
- `docs/code-style.md` documents only what tools cannot say: the tools table plus conventions and decisions.
- Brownfield: detect tools and conventions and report drift, without running anything.
- Greenfield: tools are set up from the interview with real config files.
- Every agent change runs the style checks and is reviewed against the doc.

**Non-Goals:**
- Running formatters or linters during the survey.
- Editing existing build or manifest files (`package.json`, `pyproject.toml`, `build.gradle`).
- Choosing rule sets inside a tool (groma writes the tool's recommended base config).
- Prose or commit-message style.

## Decisions

### D1: The doc links tools and documents conventions
"Enforced by tools" holds one row per tool: config path, check command and fix command. The rules themselves stay in the config. "Conventions" covers what no tool enforces. `sources` lists the config files, so C004's docs impact reports the doc when a config changes.

Alternatives: summarize tool rules in the doc (rejected: they go stale on every config change and duplicate a source of truth); make AGENTS.md the style home (rejected: AGENTS.md has a 150-line budget and is loaded every turn, so conventions belong behind a pointer).

### D2: One reference table drives detection and setup
`skills/groma-lay-out/references/code-style-tools.md` has the columns stack, tool, role, config patterns, check, fix, install, config template and default. groma-survey reads it through `../groma-lay-out/references/` for detection. When the file is missing, the survey reports "style tools not detected (groma-lay-out missing)" and does not guess. Config templates live in `skills/groma-lay-out/templates/code-style/<tool>/`. A tool without a template has an empty template column, and its setup needs editing an existing file, so groma offers it only as a snippet.

Seed rows: EditorConfig (all stacks), Prettier and ESLint (JS/TS), Biome (JS/TS, not default), Ruff (Python), gofmt and golangci-lint (Go, no config file), rustfmt and clippy (Rust), Spotless (Java/Kotlin, snippet only), RuboCop (Ruby), shellcheck and shfmt (shell).

Alternatives: one table per skill (rejected: two sources of truth for the same patterns); detect tools in `detect.sh` (rejected: detect only decides greenfield or brownfield, and style detection belongs to the survey).

### D3: Static drift only, via `style-drift.sh`
`style-drift.sh <dir>` parses `.editorconfig` sections (globs, `indent_style`, `end_of_line`, `insert_final_newline`, `trim_trailing_whitespace`) and checks tracked files (`git ls-files`) with awk. It prints `drift<TAB>property<TAB>count<TAB>examples` and `unchecked<TAB>tool<TAB>config`. The second kind means the tool's check command appears in neither `.github/workflows/*`, nor `package.json` scripts, nor `Makefile`, nor `justfile`. The `unchecked` lookup uses the table's check column. The script reads only the table and the files.

Alternatives: run `prettier --check` and similar tools (rejected: it executes project code such as JS configs and plugins, and it needs installed dependencies); skip drift entirely (rejected: a documented style the code ignores misleads agents).

### D4: Conventions are inferred by the agent, bounded and cited
The survey samples up to 10 files per top-level source folder, preferring recently changed ones (`git log`). It writes at most 12 conventions, each with a path. Areas without a clear pattern get "No consistent pattern found." This follows the EXTRACTED/INFERRED tagging already used for the data model.

Alternatives: a script heuristic for naming (rejected: language-specific code violates ADR 0004); no inference (rejected: conventions are the part that no tool captures).

### D5: Setup writes new files, installs need consent
After the interview, groma writes `.editorconfig` and template configs only when the target path does not exist. Each chosen tool gets an accepted ADR, because the user decided in the interview. Dependency installs (`npm i -D …`, `uv add --dev ruff`) change manifests and lockfiles, so they go through the consent flow of `groma-skills`/C003: run after a yes, otherwise append to `.groma/install.sh`. Brownfield default is "document only".

Alternatives: always write the configs, even in brownfield (rejected: adding a linter to years of code causes a flood of failures nobody asked for); never create configs (rejected: the user asked for setup after the interview).

### D6: The agent reaches the style through three pointers
AGENTS.md gets a pointer line plus the check commands. The methodology context gets a line when groma creates the config. groma-loop's tests gate runs the check commands, and its review prompt includes the doc. Outside the loop, the first two pointers carry the style. Inside the loop, the gate enforces it.

Alternatives: install a style skill per stack from the catalog (deferred: possible later as catalog rows; the doc stays the source); a pre-commit hook (rejected: it edits `.git/hooks` or needs a framework, which is outside groma's write scope).

## Risks / Trade-offs

- [Inferred conventions are wrong] → every line cites a path; the review of the first docs run catches it, and `INFERRED` makes the uncertainty visible.
- [Tool templates age as tools release new config formats, for example ESLint flat config] → templates are pinned per tool version in the table; refreshed with catalog updates.
- [The `unchecked` lookup misses CI systems other than GitHub Actions] → the list of CI file patterns lives in the table header; GitLab CI and similar systems can be added as rows.
- [The cross-skill read from survey to lay-out breaks when only groma-survey is installed] → explicit degradation message; the suite installs both by default.

## Migration Plan

- `upgrades.md` row 0.3.0: in update mode, fill the code-style slot like any missing mandatory doc. groma does not create tool configs in update mode unless the user asks.
- Fixtures: node-prisma gets `.prettierrc` and `eslint.config.js`; python-django-stale-docs gets `.editorconfig` with spaces plus files with tabs; java-flyway gets `CONTRIBUTING.md` with a style section.

## Open Questions

- Should catalog skills (for example a stack-specific style skill) be offered alongside the doc? Deferred until the doc has been used on real projects.
