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
