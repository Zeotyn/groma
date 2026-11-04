# Methodologies

Read only the section of the chosen methodology. Versions verified on 2026-11-04; bump them in a PR.

Agent ids used below map from groma's `agents` list: claude, copilot, gemini, cursor, codex.

## openspec (recommended)

- **Already present:** `openspec/` exists → do not run init.
- **Init:**
  ```sh
  npx --yes @fission-ai/openspec@1.16.0 init --tools <ids> --no-animation --no-copilot-cloud .
  ```
  Tool ids: `claude`, `github-copilot`, `gemini`, `cursor`, `codex` (comma-separated).
- **Touches:** `openspec/`, `.claude/commands/opsx/`, `.claude/skills/openspec-*/`, `.github/prompts/opsx-*`, `.github/skills/openspec-*/`, matching folders for other tools.
- **Link to docs** (only when this run created `openspec/config.yaml`): add a `context:` block that says "Product truth lives in docs/ (start at docs/README.md). Read the relevant docs and ADRs before writing artifacts." and under `rules.proposal` the change-naming rule from [conventions.md](conventions.md) as one double-quoted YAML string (it contains `: `, which unquoted would turn the list item into a mapping and OpenSpec would ignore the rules).
- **Changes folder:** `openspec/changes/` (archive: `openspec/changes/archive/YYYY-MM-DD-<name>/`). New milestones: `openspec new change m00N-<slug>`, add `skip_specs: true` to its `.openspec.yaml`, fill `proposal.md` from [../templates/milestone-proposal.md](../templates/milestone-proposal.md).

## spec-kit

- **Already present:** `.specify/` exists → do not run init.
- **Needs:** `uv`.
- **Init** (one primary agent; choose the first entry of `agents`):
  ```sh
  uvx --from git+https://github.com/github/spec-kit.git@v1.3.0 specify init --here --integration <id> --script sh --ignore-agent-tools
  ```
  Integration ids: `claude`, `copilot`, `gemini`, `cursor-agent`, `codex`. Never pass `--force`: it overwrites existing files. In a non-empty folder Spec Kit asks for confirmation; if it cannot run interactively, hand the command to the user via `.groma/install.sh`.
- **Touches:** `.specify/`, agent command folders.
- **Link to docs** (only when this run created `.specify/memory/constitution.md`): the constitution references `docs/vision.md` and `docs/concept.md` for product goals instead of restating them.
- **Changes folder:** `specs/` (feature folders). Name them with the convention id: `specs/c004-export-csv/`.

## bmad

- **Already present:** `_bmad/` or `.bmad-core/` exists → do not run install.
- **Install** is interactive in v6:
  ```sh
  npx bmad-method@6.12.4 install
  ```
  Always hand it to the user (`.groma/install.sh`), then continue.
- **Mapping:** epic ↔ milestone `m`, story ↔ change `c` or fix `f`. Note the mapping in AGENTS.md.

## gsd

- **Already present:** `.planning/` exists → do not run init.
- **Init** (flags from the project README, verify with `--help` on first use):
  ```sh
  npx --yes @opengsd/gsd-core@1.20.0 --claude --local
  ```
  Other agents: `--codex`, `--opencode`; Copilot and Gemini via the project's docs.
- **Mapping:** phase ↔ milestone `m`.

## none

Skip initialization. Changes still follow the naming convention in [conventions.md](conventions.md); groma's scripts look for `openspec/changes/` or `specs/`.
