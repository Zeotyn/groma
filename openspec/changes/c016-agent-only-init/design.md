## Context

`groma init` materializes the skills in `cli/skills.js` (`planSkills`, `applySkills`): for each selected agent and each groma skill folder it creates missing files, replaces copies whose hash still matches `.groma/generated.json`, keeps edited copies, reports conflicts for folders groma did not create, deletes files of removed skills only when unchanged, and writes `generated.json` (`generatedBy`, `files: {path: sha256}`). The `/groma` skill cannot run this code: skills ship without `cli/`, and a plugin user may not have the package at all. Today `/groma` therefore sends the user to `npx groma-cli update` for every copy and update.

The user decided on 2026-11-12 that copying the skills into the project is the default on the agent path, because team repositories depend on it.

## Goals / Non-Goals

**Goals:**
- A plugin-only (or `npx skills`-only) user gets the same project result as a CLI user.
- One set of materialization rules, tested on both paths.
- The project copy is the default; the user can decline.

**Non-Goals:**
- Replacing the third-party installers (OpenSpec, `npx skills`); they stay commands the agent runs with consent.
- Removing the CLI.

## Decisions

### D1: A shell script mirrors the CLI's materialization rules
`skills/groma/scripts/materialize.sh [--update] [--dry-run] --agents <list> <project>` implements the same plan as `planSkills` in POSIX sh: `find` over the skill folders next to it, `sha256sum` or `shasum -a 256`, the `generatedBy` line inserted into the SKILL.md frontmatter the way `addGeneratedBy` does, `generated.json` written with sorted keys in the CLI's format. Skills dirs per agent come from `agents.yaml`. A bats suite runs the CLI's materialization scenarios against the script, and a parity test compares both outputs byte for byte.

Alternatives: let the agent copy the files itself (rejected: not deterministic, costs tokens for every file, and cannot keep hashes reliably); call the CLI's JavaScript from the skill (rejected: skills ship without `cli/`, and plugin users may have no package); make the CLI call the shell script (rejected for now: the CLI is tested and fast; parity tests keep both honest, and it can be revisited later).

### D2: Copy by default on the agent path
In step 7 (agents) `/groma` asks once, recommended yes: "Put the groma skills into the project so the team gets them with the repository?". Yes runs `materialize.sh` for the selected agents and sets `steps.skills_copy: done` (new step key, written only by this path and by `groma init`). No records `skipped`. Update mode runs `materialize.sh --update` and reports edited copies, instead of recommending `npx groma-cli update`.

Alternatives: copy only on request (rejected by the user: teams depend on the copy); always copy without asking (rejected: some plugin users keep their repository free of tool folders).

### D3: Project copy also when the plugin is installed
The Claude plugin and the project copy both provide the skills, so Claude Code would list them twice. groma still copies (the project copy is the one teammates get) and prints, in the user's language, how to switch the plugin off for this project, with the reason. It never edits the user's settings. `groma init` changes its duplicate-plugin default from "skip" to "copy" so both paths agree; `agents_via_plugin` stays for users who choose skip.

Alternatives: keep skipping Claude when the plugin is present (rejected: the team gets no Claude skills from the repository); write a project setting that disables the plugin (rejected: groma does not edit settings it did not create, ADR 0006).

### Notes from the other M004 changes
- R001 runs first: after vendoring, every skill folder is self-contained, so `materialize.sh` copies folders as they are.
- C009 bundles: `materialize.sh` copies the groma skill folders installed next to it, so a `groma-docs` bundle puts only detect, survey and lay-out into the project.
- C014: the next-action hooks come with the plugin. Teammates who only have the project copy get the skills, not the plugin hooks; for them the settings path from C007 stays.
- S001 question 5 (ADR 0050): the hint is `claude plugin disable groma@groma --scope local`, run by the user in the project; it writes `enabledPlugins` into `.claude/settings.local.json` (not committed) and hides the plugin's skills only there. Verified: a project copy plus the enabled plugin lists each skill twice (`groma-detect` and `groma:groma-detect`).
- C015: the D2 question and the D3 hint follow the user-language rule.

## Risks / Trade-offs

- [Two implementations of one rule set drift] → bats runs the CLI scenarios against the script, and the parity test fails on any difference.
- [How to disable a plugin per project depends on Claude Code] → S001 verified `claude plugin disable <plugin> --scope local` on 2.1.322; the hint names that command.
- [Skills appear twice for a plugin user who ignores the hint] → harmless duplication; the summary repeats the hint once.

## Open Questions

- Whether `groma init` should later call `materialize.sh` instead of its own code, to keep one implementation.
- Whether a bundle (C009) should pass its skill list to `materialize.sh --update`, and whether removals should then be limited to skills the suite no longer ships at all. Today an update run from a smaller bundle removes the unchanged copies of the skills it does not ship.
- Whether the plugin hint should be suppressed once `.claude/settings.local.json` shows the plugin disabled for the project (read-only check).

## Implementation notes

- **Sort order of `generated.json` (D1).** The CLI sorted the keys with `localeCompare`, which follows the machine's locale data and cannot be reproduced in POSIX sh (`.claude/skills/groma/SKILL.md` sorts before `.../groma/agents.yaml` in byte order, after it in ICU order). `cli/skills.js` now sorts in byte order, equal to `LC_ALL=C sort` in the script. A project whose file the older CLI wrote gets its keys reordered once by the next update on either path. With this the parity test compares byte for byte and normalizes nothing.
- **Parity test scope (task 1.2).** `tests/scripts/materialize.bats` runs one generated fixture (`node-prisma`, plus a foreign `.github/skills/groma-loop/`) through `node bin/groma.js init --yes` and through `materialize.sh`, then the same edits and `groma update` versus `materialize.sh --update`. It compares the agent skill folders (content and executable bit) and `.groma/generated.json`. `.groma/config.yaml` and `.groma/pending.json` are not compared: on the agent path the agent writes the config, and `pending.json` belongs to the CLI's installer steps.
- **Options beyond D1.** `--force` (as in `groma update --force`), `--skills <list>` (limits the copied folders, for bundles whose plugin folder holds more skills than the bundle lists) and, with `--update`, agents read from `.groma/config.yaml` minus `agents_via_plugin` when `--agents` is absent. `--update` and the default mode apply the same plan, as `groma init` and `groma update` do; the flag only changes where the agents come from.
- **Copy of a copy.** When the source is itself a project copy, its `SKILL.md` already has a `generatedBy` line; the script replaces that line instead of adding a second one. The CLI never meets this case, because its source is the package.
- **Symbolic links.** A symbolic link at a destination path counts as an existing file that never matches a hash (conflict or edited), and a replaced file is removed before the copy, so the script never writes through a link. The CLI follows links.
- **Plugin detection (D3).** `materialize.sh` prints `plugin<TAB>claude<TAB>claude plugin disable groma@groma --scope local` when `claude` is among the agents and either the script runs from a path containing `/plugins/` or `claude plugin list` shows `groma@` (the CLI's check). It does not tell an enabled plugin from one already disabled for this project, so the hint can repeat after the user ran the command; the summary prints it once per run.
- **`steps.skills_copy` (D2).** In the template the key sits after `agents`, default `pending`. `groma init` writes `done` when it copied for at least one agent, `skipped` when the only agent was skipped through the plugin question. `validate-config.sh` gained a warning for unknown step keys; the existing value check already covered the new key.
- **Pending installs.** The modified "Reuse of CLI setup" requirement lets `/groma` run pending third-party installs with consent. The skill offers this once and, without a yes, behaves as before (nothing installed, Next action `npx groma-cli update`), so the `cli-node-prisma` eval assertions stay valid. Evals were not run for this change.
- **ADRs.** 0057 (D1), 0058 (D2), 0059 (D3, replaces the default of ADR 0019), all `proposed`.
- **CHANGELOG.** Not edited here: CHANGELOG by integrator (task 4.1 is ticked without it).
- **Shared files.** `materialize.sh` is not vendored: only the orchestrator runs it. `validate-config.sh` was synced to groma-skills with `scripts/sync-shared.sh`.
- **Not done.** `--update` from a bundle that ships fewer skills than the project holds treats the other skills as removed and deletes their unchanged copies, as the CLI would for a removed skill. See Open Questions.
