<p align="center">
  <img src="assets/groma-logo.svg" alt="groma: Survey. Align. Build." width="640">
</p>

<p align="center">
  <a href="https://github.com/Zeotyn/groma/actions/workflows/test.yml"><img src="https://github.com/Zeotyn/groma/actions/workflows/test.yml/badge.svg" alt="test"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-D7AD69" alt="MIT license"></a>
  <img src="https://img.shields.io/badge/agents-Claude%20Code%20%C2%B7%20Copilot%20%C2%B7%20Gemini%20%C2%B7%20Cursor%20%C2%B7%20Codex-8EC8C2" alt="agents">
</p>

> The Roman *groma* was the surveying instrument used to lay out a new town before anyone built on it. **groma** does the same for software projects: it surveys what is there, lays out the docs, and sets up your methodology and skills before the first line of new code.

groma is an open-source skill suite for AI coding agents. Run `/groma` in an empty folder or an existing repository and it will:

1. Detect whether the project is greenfield or brownfield.
2. Interview you only about what it cannot see.
3. Set up a spec methodology (OpenSpec, Spec Kit, BMAD, GSD or none).
4. Install the skills you pick from a curated catalog, per project.
5. Create or complete a living `docs/` folder: vision, concept, architecture, data model, glossary, risks and ADRs.
6. Survey existing code **without changing a single existing file**: code map, ADR harvest, stale-doc detection, data model from migrations and schemas.
7. Write one `AGENTS.md` that every agent reads.

Re-run `/groma` at any time. It only adds what is missing and reports what went stale.

**Survey. Align. Build.**

| | groma does | with |
|---|---|---|
| **Survey** | reads what exists, changes nothing | `groma-detect`, `groma-survey` |
| **Align** | lays out docs, ADRs, methodology, skills and one `AGENTS.md` | `groma-lay-out`, `groma-methodology`, `groma-skills`, `groma-agents` |
| **Build** | runs every change through a review loop with a second model | `groma-loop` |

## Install

| Agent | Command | Status |
|---|---|---|
| Claude Code | `claude plugin marketplace add Zeotyn/groma` then `claude plugin install groma@groma` | tested (local `--plugin-dir`, evals) |
| GitHub Copilot CLI | `copilot plugin marketplace add Zeotyn/groma` then `copilot plugin install groma@groma` | tested (manual protocol, [run 2026-11-04](tests/manual/copilot-2026-11-04.md)) |
| Any agent (skills CLI) | `npx skills add Zeotyn/groma --all` or a single skill: `npx skills add Zeotyn/groma --skill groma-lay-out` | tested (local path) |
| Codex | `codex plugin marketplace add Zeotyn/groma` | best effort |
| Gemini CLI | `gemini extensions install https://github.com/Zeotyn/groma` | best effort |
| Cursor | Customize → Plugins → From GitHub Repository → `Zeotyn/groma` | best effort |
| Fallback | `curl -fsSL https://raw.githubusercontent.com/Zeotyn/groma/main/install.sh \| sh` | tested (local checkout) |


## Skills

| Skill | What it does |
|---|---|
| `groma` | Orchestrator: runs every step in order, resumes, updates |
| `groma-detect` | Greenfield or brownfield, with the signals behind the verdict |
| `groma-survey` | Read-only survey of an existing project, writes a findings report |
| `groma-lay-out` | Creates or completes `docs/` |
| `groma-methodology` | Initializes OpenSpec, Spec Kit, BMAD or GSD non-interactively |
| `groma-skills` | Lets you pick third-party skills per category and installs them |
| `groma-agents` | Writes `AGENTS.md` and pointer files for each agent |
| `groma-loop` | Runs a change through propose, apply, verify and archive with an independent reviewer model |

Every skill also works on its own.

## Review loop

`groma-loop` works through one change at a time. You write (as the author agent), a different model reviews, and you must answer every finding with `fixed` or `rejected: <reason>`.

```
propose ─▶ review ⟲ ─▶ apply per task group ─▶ tests green? ─▶ review ⟲ ─▶ verify ─▶ archive
```

- **Reviewer `auto`** picks the most independent reviewer it can reach: another vendor's CLI (`codex`, `gemini`, `copilot`), else another Claude model, else a self-review in a fresh context, clearly marked as such. Pin one per phase with `review.<phase>.reviewer: gemini` or `claude:opus`.
- **Mode `autonomous`** (default) runs to the archive and stops only when it is stuck: open high findings after the last round, tests still red after retries, a rejected high finding, or a destructive step outside the change. **`gated`** also waits for you after propose and before archive.
- Every round is kept in the change folder as `reviews/<phase>-round-<n>.md` and archived with it.

Reminders: `skills/groma-methodology/scripts/status.sh` lists changes that are ready to archive, ticked without test changes, or stale. `AGENTS.md` tells agents to run it at session start; Claude Code can run it automatically through an optional SessionStart hook.

## Requirements

`git` and Node.js 22+ (`npx`). Optional: `uv` for graphify and Spec Kit. Check with `sh skills/groma/scripts/check-prereqs.sh`.

## What groma never does

- Edit, move or delete a file that existed before the run. Suggestions for existing files land in `docs/_groma/findings-<date>.md` as snippets.
- Connect to a database. The data model comes from migrations, schema files and code. If you want a live schema, run `skills/groma-survey/scripts/dump-schema.sh` yourself; groma reads only the resulting file.
- Run an installer that touches an existing file without asking first. Declined or failing installs go to `.groma/install.sh` for you to run.

## Configuration

Everything groma decided is stored in `.groma/config.yaml` inside your project. Commit it. Edit it by hand and re-run `/groma`; groma validates it and reports errors with line numbers.

```yaml
schema: 1
methodology: openspec            # openspec | spec-kit | bmad | gsd | none
workflow: superpowers            # workflow layer, or none
agents: [claude, copilot]
skills:
  design: none                   # asked only for projects with a UI
  writing: [anti-ai-slop-writing, i-have-adhd]
  pragmatism: ponytail
  diagrams: archify
  discovery: graphify
review:
  mode: autonomous               # autonomous | gated
  propose:
    reviewer: auto               # auto | self | claude|copilot|gemini|codex[:model]
    max_rounds: 2
  apply:
    reviewer: auto
    per: task-group              # task | task-group | change
    max_rounds: 1
    test_retries: 2
reminders:
  archive_when_done: true
  stale_change_days: 14
  untested_tasks: true
conventions:
  changes:
    digits: 3
    types:
      m: milestone
      c: change
      f: fix
      s: spike
      r: refactor
      d: docs
```

The full template with comments: [skills/groma/templates/config.yaml](skills/groma/templates/config.yaml). The skill catalog: [skills/groma-skills/catalog.yaml](skills/groma-skills/catalog.yaml).

## Updating

| Installed via | Update |
|---|---|
| Claude Code plugin | `claude plugin update groma` |
| npx skills | `npx skills update` |
| install.sh | `sh install.sh --ref vX.Y.Z` |

Then run `/groma` in a project: it compares `initialized_with` in the config with the new version and adds only what the new version requires.

## Conventions groma sets up

- `docs/` is the product truth. ADRs follow [MADR 4.0](https://adr.github.io/madr/).
- Changes are named `<type><NNN>-<slug>`: `m` milestone, `c` change, `f` fix, `s` spike, `r` refactor, `d` docs. Example: `c004-export-csv`.
- Project choices live in `.groma/config.yaml`, committed with the project.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Most contributions are one table row: a new stack pattern, ADR location or catalog entry.

## License

[MIT](LICENSE)
