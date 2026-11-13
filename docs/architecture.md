---
title: Architecture
status: draft
last_reviewed: 2026-11-13
review_after_days: 90
owner: Eugen Waldschmidt
sources: [skills/, hooks/, .claude-plugin/, .codex-plugin/, .cursor-plugin/, gemini-extension.json, install.sh, uninstall.sh, scripts/, tests/]
---

# Architecture

## System context

```mermaid
flowchart LR
  dev([Developer]) --> agent[AI coding agent]
  agent --> groma[groma skills]
  groma --> project[(Target project)]
  groma --> installers[Third-party installers: npx skills, claude plugin, openspec, uv]
  installers --> upstream[(Upstream skill repos on GitHub)]
```

A developer runs `/groma` inside an agent (Claude Code, Copilot, Gemini CLI, Cursor, Codex). The agent follows the skills, reads the target project, writes new files into it and calls third-party installers, or lists their commands in `.groma/install.sh`. `npx groma-cli init` is a second, equal entry: it does the deterministic part in the terminal and hands over to `/groma`. Both paths end with the same project.

## Containers

| Container | Technology | Responsibility | Evidence |
|---|---|---|---|
| Skills | Markdown (Agent Skills format) | Procedure for each step | `skills/*/SKILL.md` |
| Runtime scripts | POSIX sh | Detection, git practice, freshness, style drift, docs impact, config validation, change ids, lifecycle status, reviewer calls, schema dump, copying the groma skills into the project | `skills/*/scripts/` |
| Templates and references | Markdown, YAML | Docs, agent file and style config templates, stack tables (signals, data sources, ADR sources, style tools), skill catalog | `skills/*/templates/`, `skills/*/references/`, `skills/groma-skills/catalog.yaml` |
| Distribution manifests | JSON | Plugin and extension metadata per agent | `.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `gemini-extension.json`, `install.sh` |
| Plugin hooks | JSON | Claude Code hooks that ship with the plugin: `SessionStart` and `Stop` for the next action | `hooks/hooks.json` |
| Test suite (not shipped) | sh, bats, Python via uv | Structure checks (including identical shared copies), script tests, standalone installs, invariant, evals with a token report; `sync-shared.sh` refreshes the shared copies | `scripts/test.sh`, `scripts/sync-shared.sh`, `tests/` |

## Building blocks

- `groma`: orchestrator, owns `config.yaml` template, `check-prereqs.sh`, `validate-config.sh`, `materialize.sh` (copies the groma skills into the project) and `retired-skills.txt` (skills whose copies an update may delete).
- `groma-detect`: `detect.sh` plus `references/signals.md`; `git-practice.sh` recommends the integration strategy and commit style from the main branch's history.
- `groma-survey`: `freshness.sh`, `style-drift.sh` (tools from the lay-out table, `.editorconfig` drift, unchecked tools), `dump-schema.sh`, ADR and data-source tables, findings template.
- `groma-lay-out`: doc templates, `doc-slots.md`, `code-style-tools.md` with `templates/code-style/` (style setup) and `docs-impact.sh` (docs impact and ADR candidates of a change; on a change branch the base is the merge base with the main branch).
- `groma-methodology`: `next-change-id.sh`, `check-conventions.sh`, `roadmap.sh`, `status.sh` (lifecycle reminders), `next.sh` (the one next action, from `status.sh` output; share `lib-changes.sh`), `next-stop.sh` (debounced display wrapper for agent stop hooks) and `next-session.sh` (SessionStart wrapper that gives the next action to the agent).
- `groma-loop`: runs one change through propose, apply, verify and archive with an independent reviewer; `resolve-reviewer.sh`, `review.sh`, review prompt and record templates.
- `groma-skills`: `catalog.yaml` and `references/install.md`.
- `groma-agents`: templates for `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `copilot-instructions.md`, `groma.mdc`; `references/git-strategies.md` holds the command sequences of the three integration strategies; `claude-stop-hook.json`, `statusline-snippet.sh` and `statusline-pill.sh` for the next action. Hook support per agent (event, config file, output format, status `stable`, `experimental` or `none`) is data in `skills/groma/agents.yaml`.

Every skill works alone, because `npx skills add --skill <name>` installs one folder ([ADR 0051](adr/0051-vendor-shared-files-into-each-skill.md)). A file that more than one skill reads (a table, template or script) has one source and a vendored copy in each consumer: groma carries `code-style-tools.md`, `style-drift.sh`, `git-practice.sh`, `catalog.yaml` and the AGENTS.md template; groma-survey carries `detect.sh`, `signals.md`, `doc-slots.md`, `code-style-tools.md` and the ADR template; groma-skills and groma-agents carry `agents.yaml`; groma-methodology and groma-loop carry `docs-impact.sh`; groma-loop carries `git-strategies.md`; groma-agents carries the change naming rule `naming-rule.md`; groma-methodology carries `check-prereqs.sh`; groma-lay-out carries `install-consent.md` from groma-skills. `scripts/shared-files.txt` lists every source and copy, `scripts/sync-shared.sh` copies sources over copies, and the structure check fails when a copy differs.

Only procedure hand-offs still point into a sibling folder, listed in `scripts/handoffs.txt`: the orchestrator follows each sibling's `SKILL.md` (`../groma-detect/SKILL.md`), groma-loop follows groma-lay-out's "ADR candidates from a change" and runs groma-methodology's `roadmap.sh`, and groma-agents writes the paths of groma-methodology's `status.sh`, `next.sh`, `next-stop.sh` and groma-lay-out's `docs-impact.sh` into AGENTS.md and hook files. When the sibling is missing, the skill names the `npx skills add Zeotyn/groma --skill <name>` command and skips that step. `tests/scripts/standalone.bats` installs each skill alone and checks this.

## Runtime view

`/groma` in init mode: detect → interview (style tools asked only when `style-drift.sh` finds none; integration strategy and push policy asked in git repositories, brownfield with the recommendation and evidence of `git-practice.sh`) → write `.groma/config.yaml` → methodology → skills → docs (survey first on brownfield; style setup from the interview, then the docs tree with `docs/code-style.md`) → agents → summary. After each step `steps.<name>` becomes `done`, `pending` or `skipped`. A later run validates the config and resumes at the first `pending` step.

Skill materialization has one rule set and two implementations ([ADR 0057](adr/0057-mirror-the-cli-materialization-rules-in-a-shell-script.md)): `cli/skills.js` for `groma init` and `groma update`, and `skills/groma/scripts/materialize.sh` for `/groma`, which copies the groma skill folders installed next to it. Both copy into `<skills_dir>/groma*/` of each selected agent, add `metadata.generatedBy` to every copied `SKILL.md` and record each file's SHA-256 in `.groma/generated.json` with keys in byte order. A file is groma's to replace only while its hash matches its record: unchanged copies are replaced, edited copies are kept and reported, a file or folder without a record is a conflict and stays untouched. An unchanged file is deleted only when groma no longer ships it: the file left a copied skill, or its skill is listed in `skills/groma/retired-skills.txt`; a skill that a smaller or older source merely lacks keeps its copies, and neither path replaces copies of a newer groma without `--allow-downgrade`. Both treat a symbolic link below the skills folder, or a skills folder that leads out of the project, as a conflict, and both write `generated.json` before the first file, so a run that dies midway leaves its files recorded. `materialize.sh` refuses a source that is itself a copy groma made (its `SKILL.md` carries `generatedBy`) and never copies a folder onto itself. A parity test runs one fixture through both and compares the results byte for byte. In the agents step `/groma` asks once whether to copy (recommended yes, `steps.skills_copy`) unless `groma init` already did; update mode runs `materialize.sh --update`. When the groma Claude plugin is active as well, both paths still copy and print `claude plugin disable groma@groma --scope local`; neither runs it or edits settings ([ADR 0059](adr/0059-copy-the-skills-also-when-the-plugin-is-installed.md)).

`groma-loop` per change: propose → review rounds → apply per task group (tests gate with the code-style check commands, then review rounds on the diff with the code-style doc as project rules) → verify (plus the docs gate: every `docs-impact.sh` line is a high finding) → archive with spec sync and docs sync (proposed ADRs with this change's `origin` become accepted, `last_reviewed` of touched docs set, ADR index and roadmap updated). With `docs.gate: strict` archive waits until the report is empty. In a git repository the loop first requires a clean working tree, works on a branch named after the change, commits each review unit after its clean review, commits the archive, integrates with the configured strategy (rebase, merge or squash, the command sequence from `git-strategies.md`) and pushes the main branch by `git.push`. Before the integration the loop requires clean trees, records both refs and fast-forwards the main branch to its upstream; when the main branch is checked out in another worktree, the main-side commands run there (`git -C`). A conflicting integration is aborted, so both branches stay as they were, and escalated with the conflicting paths; a failure without conflicts stops without an abort; the loop never force-pushes, never moves the main branch by hand and never deletes branches. The main branch follows one rule for every script and skill (`git-strategies.md`, "Main branch").

`status.sh` at session start prints at most one reminder per active change (docs impact open, verify and archive, untested ticks, milestone gate, stale change), one line per ADR still `proposed` after its origin change was archived, and from local git state one line each for uncommitted files and for commits on the main branch not yet on its upstream. A milestone is at its gate when it has open tasks and no active change names it in a `Milestone:` line.

`next.sh` turns those reminders into one next action: the first rung of a fixed ladder (rebase or merge in progress, docs open, verify, uncommitted work, milestone gate, unpushed commits unless `git.push: never`, proposed ADR of an archived change, the active change with the newest commit). It checks the rebase or merge state itself and maps every other rung from one `status.sh` run. The result is cached in `.groma/.cache/next`, keyed on `HEAD`, `git status --porcelain` and the branch and remote refs, and invalidated when a file in the changes folder is newer than the cache. It reaches the user through channels that only display it, except one: the Claude Code status line (a snippet the user adds), the Claude Code Stop hook's `systemMessage` through `next-stop.sh`, which shows a line only when it changed or after `next.reshow_minutes`, the AGENTS.md "Session end" line and `npx groma-cli next`. None of these blocks the agent or feeds text back to it. The exception is the `SessionStart` hook, the one channel that gives text to the agent (ADR 0054 amends ADR 0042 for it): `next-session.sh` prints the long line as `additionalContext` once per session start, resume, clear or compaction.

In Claude Code the two hooks ship with the plugin in `hooks/hooks.json` and run `"${CLAUDE_PLUGIN_ROOT}"/skills/groma-methodology/scripts/…` for `$CLAUDE_PROJECT_DIR`, so no settings file is written; without the plugin, groma-agents offers the Stop hook through `.claude/settings.local.json`. A plugin hook runs in every project, so both scripts first test for `<project>/.groma/` and exit without output when it is missing. Then `next_on` (`lib-changes.sh`) decides: `next.hook: on` or `off` in the project config wins; unset or `auto` means on exactly when the user's flag file `~/.claude/.groma-next-always` exists. The scripts only read that file; groma prints the `touch` and `rm` commands and never runs them. Claude Code starts matching hooks in parallel, so a project with the plugin and a settings-file Stop hook starts `next-stop.sh` twice: the plugin's copy (`--plugin`) exits when a settings file of the project names `next-stop.sh`, and every copy holds the lock folder `.groma/.cache/next-stop.lock` while it reads and writes the debounce state.

`scripts/test.sh evals` (on demand only, it costs API tokens) runs `/groma` headless with `claude -p --output-format json` on fresh copies of the fixtures and checks each result with `tests/evals/assert.sh`. `tests/evals/token-report.sh` reads each fixture's JSON result and writes one row to the run's report `tests/evals/reports/<YYYY-MM-DDTHHMMSS>.tsv`: input, output, cache read and cache write tokens (summed over every model of the run), cost in USD, turns and duration. The run names its report and ends with the totals and, when the committed `tests/evals/reports/baseline.tsv` exists, the token and cost difference per fixture against it. Run reports are git-ignored; the evals workflow uploads them as an artifact.

## Deployment

Distributed from GitHub (`Zeotyn/groma`) as a Claude Code / Copilot plugin marketplace, via `npx skills add`, as Codex, Cursor and Gemini manifests, through `install.sh`, and on npm as `groma-cli` (`npx groma-cli init`, command `groma`). Nothing runs as a service.

The Claude Code marketplace (`.claude-plugin/marketplace.json`) lists three bundles, all with `source: "./"` and one shared version: `groma` loads every skill under `skills/`, `groma-docs` lists `skills/groma-detect`, `skills/groma-survey` and `skills/groma-lay-out`, `groma-loop` lists `skills/groma-loop` ([ADR 0050](adr/0050-ship-bundles-and-hooks-through-the-plugin-manifest.md)). No skill folder is copied per bundle; each skill folder is self-contained ([ADR 0051](adr/0051-vendor-shared-files-into-each-skill.md)). Every bundle takes the name of `.claude-plugin/plugin.json`, so skills are prefixed `groma:` whichever bundle is installed and the bundles are alternatives. The structure check `bundles` pins each bundle's skill list; `tests/scripts/bundles.bats` installs each one into an isolated Claude config without login or model call, in CI (`.github/workflows/test.yml` installs Claude Code) and locally when `claude` is on PATH. That a bundle's skills work alone with a model is the manual protocol `tests/manual/claude-bundles.md`.

Releases start from a pushed tag `v<version>`: `.github/workflows/release.yml` runs `scripts/release-check.sh` (tag equals every manifest version and every marketplace bundle's version, `CHANGELOG.md` has the section), test levels 1 to 3, then `npm publish --provenance` through npm trusted publishing (OIDC, no token) and a GitHub release with the CHANGELOG section as notes.

## Decisions

Architecture decisions are recorded in [adr/](adr/README.md).
