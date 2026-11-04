# AGENTS.md

Instructions for coding agents working **on the groma repository itself**.

## What this repo is

A skill suite (Markdown skills + POSIX shell scripts) that initializes other projects. Skills live in `skills/<name>/SKILL.md`. Each skill carries its own `scripts/`, `templates/` and `references/`, because `npx skills` installs skill folders only. Repo-level `scripts/` is for development (tests) and is not shipped.

## Commands

- `scripts/test.sh` runs structure checks and script tests. Run it before every commit.
- `scripts/test.sh evals` runs headless agent evals on fixtures (costs tokens).
- `shellcheck -s sh` must pass for every `*.sh` (scripts/, skills/*/scripts/, tests/, install.sh, uninstall.sh).

## Conventions

- Work through OpenSpec changes in `openspec/changes/`. Change names follow `<type><NNN>-<slug>` (`m` milestone, `c` change, `f` fix, `s` spike, `r` refactor, `d` docs). Get the next id with `skills/groma-methodology/scripts/next-change-id.sh <type>`.
- Child changes reference their milestone with a `Milestone: mNNN` line at the top of `proposal.md`.
- Artifacts, skills and docs are written in English.
- Skill folder names start with `groma-` (except the orchestrator `groma`), and the SKILL.md `name` equals the folder name.
- Stack-specific knowledge goes into `references/*.md` tables, never into skill logic.
- Never write code that edits or deletes existing files in a target project. Writes go to new paths, `.groma/` or `docs/_groma/` only.
- Scripts never connect to databases and never print credentials.
- Keep every manifest version equal to the latest `CHANGELOG.md` release.
