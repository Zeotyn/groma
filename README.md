<p align="center">
  <img src="assets/groma-logo.svg" alt="groma: Survey. Align. Build." width="640">
</p>

<p align="center">
  <a href="https://github.com/Zeotyn/groma/actions/workflows/test.yml"><img src="https://github.com/Zeotyn/groma/actions/workflows/test.yml/badge.svg" alt="test"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-D7AD69" alt="MIT license"></a>
  <img src="https://img.shields.io/badge/agents-Claude%20Code%20%C2%B7%20Copilot%20%C2%B7%20Gemini%20%C2%B7%20Cursor%20%C2%B7%20Codex-8EC8C2" alt="agents">
</p>

# groma: project setup skills for AI coding agents

Spec-driven development, living docs with ADRs, code style and one `AGENTS.md` for Claude Code, GitHub Copilot, Gemini CLI, Cursor and Codex. npm package: [`groma-cli`](https://www.npmjs.com/package/groma-cli).

> The Roman *groma* was the surveying instrument used to lay out a new town before anyone built on it. **groma** does the same for software projects: it surveys what is there, lays out the docs, and sets up your methodology and skills before the first line of new code.

groma is an open-source skill suite (Agent Skills format) for AI coding agents. Run `/groma` in an empty folder or an existing repository and it will:

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
| **Survey** | reads what exists (code, docs, ADRs, style tools and drift), changes nothing | `groma-detect`, `groma-survey` |
| **Align** | lays out docs, ADRs, code style, methodology, skills and one `AGENTS.md` | `groma-lay-out`, `groma-methodology`, `groma-skills`, `groma-agents` |
| **Build** | runs every change through a review loop with a second model; tests and style checks gate every review | `groma-loop` |

## When to use groma

- **You want an `AGENTS.md` generator.** groma writes one canonical `AGENTS.md` plus `CLAUDE.md`, `.github/copilot-instructions.md`, `GEMINI.md` and `.cursor/rules/groma.mdc` pointers, under 150 lines, from what it found in the repo.
- **You are onboarding an existing repository (brownfield) for Claude Code or Copilot.** The survey reads code, migrations, docs and ADRs without changing a file, and reports what is stale.
- **You want spec-driven development with an AI agent.** groma installs OpenSpec, Spec Kit, BMAD or GSD non-interactively and wires it to the docs.
- **You want living documentation and architecture decision records (ADRs)** that a change must update before it is archived.
- **You want a second model to review every change** before it lands, with tests and code style checks as the gate.

## Install

Recommended: run the CLI in your project (Node.js 22+). It copies the groma skills into each agent's skill folder, sets up the methodology and catalog skills, writes `.groma/config.yaml` and then hands over to `/groma`.

```sh
npx groma-cli init
```

Other paths:

| Agent | Command | Status |
|---|---|---|
| Claude Code | `claude plugin marketplace add Zeotyn/groma` then `claude plugin install groma@groma` | tested (local `--plugin-dir`, evals) |
| GitHub Copilot CLI | `copilot plugin marketplace add Zeotyn/groma` then `copilot plugin install groma@groma` | tested (manual protocol, [run 2026-11-04](tests/manual/copilot-2026-11-04.md)) |
| Any agent (skills CLI) | `npx skills add Zeotyn/groma --all` or a single skill: `npx skills add Zeotyn/groma --skill groma-lay-out` | tested (local path) |
| Codex | `codex plugin marketplace add Zeotyn/groma` | best effort |
| Gemini CLI | `gemini extensions install https://github.com/Zeotyn/groma` | best effort |
| Cursor | Customize → Plugins → From GitHub Repository → `Zeotyn/groma` | best effort |
| Fallback | `curl -fsSL https://raw.githubusercontent.com/Zeotyn/groma/main/install.sh \| sh` | tested (local checkout) |

### Claude Code bundles

The Claude Code marketplace also offers parts of groma, for when you want only some skills and no CLI. Each bundle installs only its skills and carries the same version as the full plugin.

| Bundle | Skills | Install |
|---|---|---|
| `groma` | all eight | `claude plugin install groma@groma` |
| `groma-docs` | groma-detect, groma-survey, groma-lay-out | `claude plugin install groma-docs@groma` |
| `groma-loop` | groma-loop | `claude plugin install groma-loop@groma` |

Run `claude plugin marketplace add Zeotyn/groma` first. All bundles name their skills `groma:<skill>`, so pick one bundle: installing two adds nothing the larger one lacks. Without the full plugin, a step that hands over to a missing skill (for example groma-loop writing ADR candidates through groma-lay-out) names the skill to add and skips that step. Bundles are tested with Claude Code only (`tests/scripts/bundles.bats`, run in CI, and the manual protocol [tests/manual/claude-bundles.md](tests/manual/claude-bundles.md)); on the Copilot CLI they are untested, so install `groma@groma` there.


## CLI

Node.js 22+. Commands:

| Command | What it does |
|---|---|
| `npx groma-cli init [path]` | Copies the skills for each agent, runs the methodology init and catalog installs, writes `.groma/config.yaml` and `.groma/generated.json` |
| `npx groma-cli update` | Refreshes generated skill copies, re-runs pending steps, bumps `initialized_with` |
| `npx groma-cli status` | Prints the change status (same as `status.sh`) |
| `npx groma-cli next` | Prints the one next action (`--short` for a status line, `--json`); nothing when nothing is open |
| `npx groma-cli doctor` | Checks prerequisites, config and generated files |

Main `init` flags: `--agents`, `--methodology`, `--workflow`, `--skills`, `--review`, `--ui`, `--yes` (recommended answers, no questions), `--print` (write install commands to `.groma/install.sh` instead of running them), `--dry-run` (show the plan, write nothing), `--force` (`update` only: replace generated files you edited). Skills for agents covered by an installed Claude plugin are not copied; the config lists them in `agents_via_plugin`. Exit codes: 0 ok, 1 failure, 2 usage error, 3 prerequisites missing (for example Node older than 22).

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
- **Git** follows the `git` section of the config: a branch per change, one commit per reviewed task group, an archive commit, then integration by `integrate` (`rebase` rebases and fast-forwards, `merge` makes a `--no-ff` merge commit, `squash` one commit named after the change) and a push of the main branch by `push` (`ask`, `auto`, `never`). The same rule lands in `AGENTS.md`, so "merge this branch" means the configured strategy for every agent. A conflict is aborted and handed to you with the paths; groma never force-pushes and never deletes branches. The interview recommends the strategy from your history (`skills/groma-detect/scripts/git-practice.sh`).

Reminders: `skills/groma-methodology/scripts/status.sh` lists changes whose docs need an update, that are ready to archive, ticked without test changes, or stale, plus ADRs still `proposed` after their change was archived. `AGENTS.md` tells agents to run it at session start; Claude Code can run it automatically through an optional SessionStart hook.

## Next action

`skills/groma-methodology/scripts/next.sh` names the one thing to do next, or prints nothing. It takes the first rung that applies: a rebase or merge in progress, a done change with docs open, a done change to verify, uncommitted files, a milestone at its gate, unpushed commits (skipped with `git.push: never`), a proposed ADR whose change is archived, then the active change you last worked on.

```
$ npx groma-cli next
Push 3 commits on main: git push
$ npx groma-cli next --short
push 3
```

A warm run takes well under 300 ms: the result is cached in `.groma/.cache/` until `HEAD`, the working tree, the refs or the changes folder change. The folder ignores itself, so it never shows up in `git status`.

**In Claude Code with the groma plugin.** The plugin ships two hooks in `hooks/hooks.json`, so no settings file changes:

- `SessionStart` (startup, resume, `/clear`, compaction) gives the long line to the agent as context, once per session start, so it knows where the work stands.
- `Stop` runs `next-stop.sh`, which shows `▶ Next: …` as a message to you, only when the suggestion changed or after `next.reshow_minutes` (default 30, `0` = only on change). It never blocks or prompts the agent.

Both are silent, and return within milliseconds, in a project without `.groma/` and while the next action is off. On and off:

| `next.hook` in `.groma/config.yaml` | Next action |
|---|---|
| `on` | on in this project |
| `off` | off in this project |
| unset or `auto` (the template) | on exactly when the file `~/.claude/.groma-next-always` exists |

```sh
touch ~/.claude/.groma-next-always   # on in every groma project
rm ~/.claude/.groma-next-always      # off again
```

groma prints these commands and never runs them: it deliberately neither looks nor writes outside your project.

**Without the plugin (opt-in).** groma-agents offers the same Stop hook through `.claude/settings.local.json`, installs it only after you agree and sets `next.hook: on`. Copilot CLI (stderr with exit 2), Gemini CLI and Codex have experimental adapters in `skills/groma/agents.yaml`; Cursor has none and relies on the `AGENTS.md` line that asks agents to name the next action at the end of a session.

**Status line (Claude Code).** groma never edits your status line. Add this to your status line script, with `$project_dir` set to `workspace.project_dir` from the JSON Claude Code passes on stdin:

```sh
n=$(sh /path/to/groma-methodology/scripts/next.sh --short "$project_dir") && [ -n "$n" ] && printf ' ▶ %s' "$n"
```

Your status line already renders pills? `skills/groma-agents/templates/statusline-pill.sh` holds the same line as a colored pill. No status line yet? `skills/groma-agents/templates/statusline-snippet.sh` is a complete one.

## Living docs

Every change keeps `docs/` current in the same change, like its code. `skills/groma-lay-out/scripts/docs-impact.sh <change-dir>` compares the files changed since the change started with each doc's frontmatter `sources` and lists docs that need an update. It also lists design decisions with an "Alternatives" paragraph that have no ADR with `origin: <change>#D<n>`. To keep a doc as it is, add a task line `Docs: <path> unchanged, because <reason>`.

`docs.gate` in `.groma/config.yaml` sets how hard this is enforced:

| `docs.gate` | Status reminder | OpenSpec rules | Verify finding (groma-loop) | Blocks archive |
|---|---|---|---|---|
| `off` | no | no | no | no |
| `remind` | yes | no | no | no |
| `review` (default) | yes | yes | high | no |
| `strict` | yes | yes | high | yes |

On archive, groma-loop accepts the change's proposed ADRs, sets `last_reviewed` in the docs the change touched, completes the ADR index and regenerates the roadmap. `docs.adr_from` picks which decisions need an ADR: `design-alternatives` (default), `marked` (a line `ADR: yes`) or `off`.

## Requirements

`git` and Node.js 22+ (`npx`). Optional: `uv` for graphify and Spec Kit. Check with `sh skills/groma/scripts/check-prereqs.sh`.

## What groma never does

- Edit, move or delete a file that existed before the run. Suggestions for existing files land in `docs/_groma/findings-<date>.md` as snippets.
- Connect to a database. The data model comes from migrations, schema files and code. If you want a live schema, run `skills/groma-survey/scripts/dump-schema.sh` yourself; groma reads only the resulting file.
- Run an installer that touches an existing file without asking first. Declined or failing installs go to `.groma/install.sh` for you to run.
- Force-push, delete a branch, rewrite commits on the main branch or resolve a merge conflict on its own. A conflicting integration is aborted and handed to you.

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
docs:
  gate: review                   # off | remind | review | strict
  adr_from: design-alternatives  # design-alternatives | marked | off
reminders:
  archive_when_done: true
  stale_change_days: 14
  untested_tasks: true
git:
  integrate: rebase              # rebase | merge | squash
  branch_per_change: true
  commits: conventional          # conventional | free
  push: ask                      # ask | auto | never
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
| `npx groma-cli init` | `npx groma-cli update` (refreshes copied skills, keeps files you edited unless `--force`, re-runs pending steps) |
| install.sh | `sh install.sh --ref vX.Y.Z` |

Then run `/groma` in a project: it compares `initialized_with` in the config with the new version and adds only what the new version requires.

## Conventions groma sets up

- `docs/` is the product truth. ADRs follow [MADR 4.0](https://adr.github.io/madr/).
- Changes are named `<type><NNN>-<slug>`: `m` milestone, `c` change, `f` fix, `s` spike, `r` refactor, `d` docs. Example: `c004-export-csv`.
- Project choices live in `.groma/config.yaml`, committed with the project.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Most contributions are one table row: a new stack pattern, ADR location or catalog entry.

## Releasing

A pushed tag `v<version>` releases groma. `.github/workflows/release.yml` checks the tag against every manifest version and the CHANGELOG (`scripts/release-check.sh`), runs test levels 1 to 3, publishes `groma-cli` to npm with provenance and creates the GitHub release from the CHANGELOG section.

1. Set the version in the plugin manifests, every bundle entry of `.claude-plugin/marketplace.json`, `package.json` and `skills/groma/VERSION`; rename `[Unreleased]` in `CHANGELOG.md` to `[<version>] - <date>`.
2. Run `sh scripts/release-check.sh v<version>`, commit, push `main`.
3. `git tag v<version> && git push origin v<version>`.

npm trusts the workflow through trusted publishing: on npmjs.com, `groma-cli` has the trusted publisher GitHub Actions `Zeotyn/groma` with workflow `release.yml`, direct publish allowed, and publishing access set to "require two-factor authentication and disallow bypass tokens". The repository holds no npm token.

## License

[MIT](LICENSE)
