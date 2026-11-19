# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Repository offer and first commit (change C18). Outside a git work tree, `/groma` and `npx groma-cli init` ask "Set up a git repository here?" (recommended for greenfield, not for brownfield; `--git init|skip`); yes runs `git init` on `main` and writes a `.gitignore` from the new stack table `references/gitignore.md` only when none exists. A folder inside a parent repository names it and asks whether to use it. Before the summary, a repository without commits is offered a first commit `chore: set up project with groma <version>` with your git identity (`--commit yes|no`); without an identity nothing is committed and the next action names the commands. A declined repository is recorded as `git.enabled: false`: AGENTS.md gets no Git workflow section, groma-loop skips its git steps, and `docs-impact.sh` reports ADR candidates with a `note` instead of failing outside git or before the first commit. ADRs 0075 to 0078.

## [0.4.0] - 2026-11-18

### Breaking

- Change names without padding and milestones in the roadmap (change C017). New changes are named `<type><N>-<slug>` (`c17-export`, not `c017-export`); a change of milestone N is `m<N>-<slug>`, with an optional type word (`m3-spike-…`, `m3-fix-…`, `m3-refactor-…`). A milestone is no longer a change: its title, `**Goal:**` and `**Release gate:**` checklist live in a hand-written `## M<N>: <title>` section of `docs/roadmap.md`, and `roadmap.sh` only fills the text between `<!-- groma:changes m<N> -->` and `<!-- /groma:changes -->`; it no longer generates the file. The `d` type is gone (docs belong to the change that causes them), `conventions.changes.digits` is ignored with a warning, `next-change-id.sh` prints `c17` and `next-change-id.sh m` the next milestone number. The release-gate reminder comes from the roadmap once a milestone has a change and none is active. Nothing is renamed: if you run `check-conventions.sh` in CI, old names in the form `<type>0NN-<slug>` stay green with INFO lines, archived names are never reported, and every other name that existed before the update belongs into `.groma/conventions-baseline.txt` first; `check-conventions.sh --suggest-migration` prints new names and roadmap sections without changing a file. ADRs 0062 to 0068.

### Added

- Effect eval (change C013): `sh tests/evals/effect.sh [fixture]` runs one scripted task on a fixture without and with groma's setup, at least three runs per side, and states the maximum cost before it starts. Before any API call it checks the claude CLI, the user-level skill source and the commands the fixture's acceptance test needs (`# Requires:` line). It writes `tests/evals/reports/effect-<date>.tsv` only when every run is done: header lines with the requested model, the setup cost and model and the known limit (both sides load your user-level Claude Code settings, CLAUDE.md and skills), one row per run with pass, result subtype (a budget stop shows as `error_max_budget_usd`), permission denials and model id, then median, min and max per side, pass rates and the difference. `token-report.sh meta` prints a result's subtype, denials and model ids. First run (go-no-db, 3 runs per side, `claude-opus-5-5`): equal pass rate 3/3; the median task cost was USD 0.06 without and USD 0.62 with groma's setup, plus USD 1.77 for the setup itself.
- Skill copies without the CLI (change C016): `/groma` copies the groma skills into the project by default (one question, yes recommended), through `skills/groma/scripts/materialize.sh`, with the same rules and the same `.groma/generated.json` as `npx groma-cli init`: missing files are created, unchanged copies replaced, edited ones kept and reported, foreign folders and anything behind a symlink left alone. A copy is deleted only when it left a skill the source ships or its skill is listed as retired, and an older groma refuses to downgrade newer copies unless you pass `--allow-downgrade` (`--force` only replaces edited files). A run is crash-safe, refuses to run from the project's own copy, and makes no copies after you declined. With the Claude plugin installed groma still copies (the copy is what your team gets) and prints `claude plugin disable groma@groma --scope local`, which it never runs. `groma init` and `groma update` follow the same rules. ADRs 0057 to 0059.
- Next-action hooks in the plugin (change C014): the groma Claude Code plugin ships `hooks/hooks.json`. At session start (also after resume, clear and compaction) the agent gets the next action as one line of context; after each answer the debounced, display-only Stop line shows it to you. Both stay silent in projects without `.groma/` (about 10 ms). Project `next.hook: on|off` wins; unset or `auto` follows the global flag file `~/.claude/.groma-next-always`, which only you create (groma prints the command). A lock and a `--plugin` check keep the line from showing twice when the older settings-file hook is also present. A status-line pill is offered as a snippet; it is safe in zsh. Configs from 0.3.0 keep `hook: off`. ADRs 0052 to 0056.
- Claude Code bundles (change C009): the marketplace offers `groma` (all skills), `groma-docs` (detect, survey, lay-out) and `groma-loop`, as entries with their own skill list and no copied folders. Bundles share the `groma:` namespace, so install one of them. `scripts/release-check.sh` checks the version of every bundle entry and names the one that differs; the bundle install test now also runs in CI.

### Changed

- groma talks to you in your language (change C015): every skill asks, summarizes, hints and escalates in the language of your latest message, and gives the reasons for the commands it prints in it too; commands, paths, config keys and ids stay literal. Files groma writes into the repository keep their language, and which language generated project docs should use is an open question. ADR 0070 (proposed).
- Every groma skill works when installed alone (change R001), for example with `npx skills add Zeotyn/groma --skill groma-survey`. Shared tables, templates and scripts are vendored into each skill that reads them and kept byte-identical by `scripts/sync-shared.sh` and a structure check; only procedure hand-offs between skills remain, each with an "add skill X" message. The full suite behaves as before. ADR 0051.
- Always-loaded diet (change C011): the eight skill descriptions are shorter (2384 to 1817 characters in total) and the AGENTS.md template drops restated lines (54 to 53 lines, 3246 to 3013 characters). The structure check caps each description at 400 characters, all descriptions together at 2000, and the template at 80 lines and 3200 characters; groma-agents keeps a generated AGENTS.md within 80 lines (was 150). ADR 0071 (proposed).
- Brownfield survey in a subagent (change C012): `/groma` runs groma-survey in a subagent where the agent has one (in Claude Code the Agent tool), so the main session keeps only the hand-off and reads report sections as the docs step needs them. The subagent replies with the filled findings report; the main session writes it unchanged and runs `report-check.sh`, which also names a missing `generated_by` line and empty sections. The survey maps first, reads targeted and caps findings per category. Agents without subagents run the survey inline as before. A brownfield eval run costs about $0.45 to $0.55 more than before. ADR 0069.

### Fixed

- OpenSpec 2.x projects get working commands (fix F009): the next action prints the skill commands `/openspec-apply-change`, `/openspec-verify-change` and so on when the project has OpenSpec skills (`.agents/skills/openspec-*`) and no `opsx` command folder, as with every 2.x install and a 1.x install for Codex, `/opsx:` commands while a 1.x command folder exists (also next to 2.x skills), and no command when it finds neither. groma tells the generations apart from files in the project only, with the marker paths and command forms in the `generations` list of `methodologies.yaml`; the installer counts `.agents/skills/openspec-*` as OpenSpec's files. AGENTS.md and groma-loop name the propose skill for both versions. New projects still start on OpenSpec 1.16.0. ADR 0073.
- Evals test the checkout they run from (fix F010): `tests/evals/run.sh` stops with exit 3, before any API call, when a user-level skill `groma` or `groma-*` in `~/.claude/skills` (or `$CLAUDE_CONFIG_DIR/skills`) resolves outside this checkout's `skills/`, and names the path and the fix. Claude Code loads those skills next to `--plugin-dir`, so an eval from a worktree had tested the main checkout's skill text. `GROMA_EVAL_ALLOW_USER_SKILLS=1` turns the stop into a warning.

## [0.3.0] - 2026-11-12

### Added

- Code style (change C005): mandatory doc `docs/code-style.md` with a tools table (config, check, fix), conventions tagged `EXTRACTED` or `INFERRED` with paths, and decision links; an existing `CONTRIBUTING.md` or style guide fills the slot. `style-drift.sh` in groma-survey detects style tools from the new reference table `code-style-tools.md`, reports `.editorconfig` drift (indentation, line endings, final newline, trailing whitespace) and tools whose check runs in no CI workflow or script, without running any project tool. Greenfield, or brownfield without tools: the interview recommends the stack's defaults; after a yes groma creates `.editorconfig` and the tools' base configs from `templates/code-style/`, records one accepted ADR per tool and routes installs through the consent flow. AGENTS.md gets a "Code style" section with the check commands, the OpenSpec context a code-style line, and groma-loop runs the checks in the tests gate and reviews against the doc (tool rule: high, convention: medium).
- `.editorconfig` and `docs/code-style.md` for this repository; ADRs 0031 to 0036.
- Git workflow (change C006): config section `git` with `integrate` (`rebase`, `merge`, `squash`), `branch_per_change`, `commits` (`conventional`, `free`) and `push` (`ask`, `auto`, `never`), validated with closest-value hints; missing keys mean rebase, branch per change, conventional, ask. `git-practice.sh` in groma-detect recommends the strategy and commit style from the main branch's history with evidence (pull-request merges, `(#n)` subjects, conventional subjects), and the interview shows it. AGENTS.md gets a "Git workflow" section rendered from the config and the new strategies table `git-strategies.md` (groma-agents): a request to "merge" means the configured sequence, conflicts stop, no force-push, no branch deletion. groma-loop requires a clean tree, branches per change, commits each review unit after a clean review, commits the archive, integrates by strategy with abort-and-escalate on conflicts and pushes the main branch by policy. `docs-impact.sh` compares with the merge base of the main branch on a change branch.
- `git` section in this repository's config (rebase, push ask) and a "Git workflow" section in its AGENTS.md; ADRs 0037 to 0041.
- Next action (change C007): `next.sh` in groma-methodology prints the one next action from a fixed ladder over `status.sh` (rebase or merge in progress, docs open, verify, uncommitted, milestone gate, unpushed unless `git.push: never`, proposed ADR, active change), as a sentence with the command, `--short` (at most 20 characters) or `--json`, cached in a self-ignoring `.groma/.cache/`. `npx groma-cli next`. `next-stop.sh` shows it after each answer through the Claude Code Stop hook as `systemMessage`, debounced by `next.reshow_minutes`, never blocking the agent; `--stderr` for Copilot CLI. Config section `next` (`hook`, `reshow_minutes`) with validation, `hook` adapters per agent in `agents.yaml` (claude stable; copilot, gemini, codex experimental; cursor none), a status-line snippet that groma prints but never installs, and a "Session end" line in the AGENTS.md template. ADRs 0042 to 0044 (proposed).
- Release workflow (change C008): a pushed tag `v<version>` publishes `groma-cli` to npm from GitHub Actions through npm trusted publishing (OIDC, no token, with provenance) and creates the GitHub release from the CHANGELOG section. `scripts/release-check.sh` checks the tag against every manifest version and the CHANGELOG before anything is published. ADRs 0048 and 0049.

## [0.2.2] - 2026-11-04

### Fixed

- `status.sh` no longer says "nothing open" while work is open (fix F002): a milestone with open tasks and no active child gets `gate: <first open task>`, and uncommitted files and commits on the main branch not yet on its upstream get one line each, from local git state only. Turn the new lines off with `reminders.uncommitted` and `reminders.unpushed`.
- `freshness.sh` no longer reports docs as stale when their sources changed on the day of `last_reviewed` (fix F003). A source commit now counts only when it is newer than the doc and falls on a later day; the stale reason names `last_reviewed`. Docs without `last_reviewed` behave as before.

## [0.2.1] - 2026-11-04

### Fixed

- The npm package is now `groma-cli`, because npm rejects the name `groma` as too similar to existing packages (fix F004). Run `npx groma-cli init`; the installed command stays `groma`. 0.2.0 was tagged but never published to npm.

## [0.2.0] - 2026-11-04

### Added

- npm CLI `groma` (change C003): `npx groma init` copies the skills into each agent's project skill folder, runs the methodology init and catalog installs and writes `.groma/config.yaml`, `.groma/generated.json` and `.groma/pending.json`; `update` refreshes copies and re-runs pending steps; `status` and `doctor` complete the set. Requires Node.js 22+.
- Config key `agents_via_plugin` for agents whose skills come from an installed plugin.
- Shared data files `skills/groma/agents.yaml` and `skills/groma-methodology/methodologies.yaml`, read by both the CLI and the skills.
- `/groma` skips the config, methodology and skills steps when the CLI marked them `done`.
- Living docs (change C004): `docs-impact.sh` in groma-lay-out reports docs whose sources a change touched without updating them and design decisions without an ADR; config keys `docs.gate` (`off`, `remind`, `review`, `strict`) and `docs.adr_from`; ADR frontmatter `origin: <change>#D<n>`; groma-loop adds the report to verify as high findings and runs a docs sync on archive; `status.sh` reminds about open docs impact and ADRs still proposed after archive; OpenSpec rules for a Docs impact section, a Docs task group and decision alternatives; a living-docs line in the AGENTS.md template.
- ADRs 0009 to 0026 for the decisions of C002, C003 and C004.

### Changed

- Install recipes moved out of skill logic into `methodologies.yaml` and `agents.yaml`.

### Fixed

- `freshness.sh` no longer reports ADRs as stale after code changes; an ADR with `status: proposed` older than `--adr-days` (default 30) is stale instead (fix F001). Sources inside the docs folder are ignored. Missing sources and sources inside `openspec/changes/` are reported as `broken`; the summary line gains a trailing `broken=<n>` field.

## [0.1.0] - 2026-11-04

### Added

- Initial groma skill suite (change C001, milestone M001): orchestrator `/groma` and six sub-skills for detection, read-only survey, docs layout, methodology setup, skill catalog and agent instructions.
- Change naming convention `<type><NNN>-<slug>` with next-id, check and roadmap scripts.
- Distribution as Claude Code plugin marketplace, via `npx skills`, manifests for Codex, Cursor and Gemini CLI, and `install.sh`.
- Review loop skill `groma-loop` (change C002, milestone M001): propose, apply, verify and archive with an independent reviewer model, reviewer `auto` selection, `autonomous` and `gated` modes, review records in the change folder.
- Lifecycle reminders: `status.sh` lists changes ready to archive, ticked without test changes or stale; AGENTS.md session-start line and optional Claude Code SessionStart hook.
- `review` and `reminders` sections in `.groma/config.yaml`.
- Test suite: structure checks, 105 script tests, never-overwrite invariant, headless agent evals on six fixtures.
