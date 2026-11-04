# Methodologies

Commands, detection paths, prerequisites, agent-id mappings, touched paths and docs-link texts live in [../methodologies.yaml](../methodologies.yaml), shared with the `groma` CLI. This file explains how to apply a recipe. Read only the section of the chosen methodology.

## Applying a recipe

1. **Already present:** any `detect` path exists → do not run init; the step is done.
2. **Prerequisites:** every command in `requires` must be on PATH; otherwise the step is pending.
3. **Command:** replace `{agents}` in `init` with the `agent_ids` of the configured agents (agents without an id are dropped), joined by `separator` (default `,`). `agents: first` uses only the first configured agent.
4. **Ask first:** when a `touches` path already exists, ask the user once before running. `interactive: true` means the command needs a person at the terminal: hand it over via `.groma/install.sh`.
5. **Link to docs:** only when this run created `docs_link.file`, append `docs_link.append` to it. For a file that existed before, put the text into the findings report as a snippet.

Never pass overwrite flags such as `--force`.

## openspec (recommended)

- **Link to docs:** the appended `rules.proposal` item is one double-quoted YAML string; it contains `: `, which unquoted would turn the list item into a mapping and OpenSpec would ignore the rules. The full naming rule is in [conventions.md](conventions.md).
- **Changes folder:** `openspec/changes/` (archive: `openspec/changes/archive/YYYY-MM-DD-<name>/`). New milestones: `openspec new change m00N-<slug>`, add `skip_specs: true` to its `.openspec.yaml`, fill `proposal.md` from [../templates/milestone-proposal.md](../templates/milestone-proposal.md).

## spec-kit

- One primary agent (the first entry of `agents`). In a non-empty folder Spec Kit asks for confirmation, so it is interactive.
- **Changes folder:** `specs/` (feature folders). Name them with the convention id: `specs/c004-export-csv/`.

## bmad

- Install is interactive in v6: always hand it to the user (`.groma/install.sh`), then continue.
- **Mapping:** epic ↔ milestone `m`, story ↔ change `c` or fix `f`. Note the mapping in AGENTS.md.

## gsd

- Flags from the project README; verify with `--help` on first use. Copilot and Gemini have no flag yet: set them up via the project's docs.
- **Mapping:** phase ↔ milestone `m`.

## none

Skip initialization. Changes still follow the naming convention in [conventions.md](conventions.md); groma's scripts look for `openspec/changes/` or `specs/`.
