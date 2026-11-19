## Why

On a greenfield folder without git, `/groma` skips the git questions, still writes `git` defaults to `.groma/config.yaml` and a "Git workflow" section to AGENTS.md, and leaves a project in which later steps break: `docs-impact.sh` stops with "not a git repository with commits", so the docs gate of the first change cannot run, and groma-loop silently drops every git step. Offering to set up the repository, with a first commit, closes that gap at the moment the user is already answering setup questions.

## What Changes

- Interview (`/groma` step 2): when the project folder is not inside a git work tree, ask "Set up a git repository here?" (greenfield: yes recommended; brownfield: no recommended, because the code came from somewhere else). Yes runs `git init` with `main` as the initial branch, then the existing integration and push questions follow. When the folder is inside a repository whose top level is a parent folder (for example a dotfiles repository in the home folder), ask whether to use that repository or create one for the project.
- `.gitignore`: when groma set up the repository and the project has no `.gitignore`, write one from a new stack reference table (`references/gitignore.md`), additive only.
- First commit: a new question before the summary, "Record the setup as the first commit?" (yes recommended), offered when the repository has no commit yet. It stages the project's files and commits with the user's git identity and a fixed message; without an identity it commits nothing and the summary's next action says how to set one.
- Declined git: the config records `git.enabled: false`; AGENTS.md gets no "Git workflow" section; groma-loop skips its git steps without asking; `docs-impact.sh` reports that it cannot compare without git instead of failing with exit 2.
- CLI: `npx groma-cli init` asks the same repository question (`--git init|skip`, `--yes` takes the recommendation) and offers the first commit at its end, so both entry points give the same project.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `orchestration`: the interview offers a repository when there is none, and the run offers a first commit.
- `git-workflow`: the git settings gain `enabled`; repository setup and first-commit rules.
- `agent-instructions`: the "Git workflow" section is left out when git is off.
- `living-docs`: the docs impact report states that it cannot compare outside git, instead of failing.
- `cli`: `groma init` asks the repository question and offers the first commit.

## Docs impact

- `docs/concept.md`: the interview and the end of the run (repository offer, first commit).
- `docs/architecture.md`: where `git init` and the first commit run (skill step and CLI), and the new `references/gitignore.md` table.
- `docs/data-model.md`: `git.enabled` in `.groma/config.yaml`.
- `docs/glossary.md`: unchanged unless a new term appears; decided in the Docs task group.
- ADRs: one per design decision D1 to D4 (proposed, `origin: c18-git-setup#D<n>`).

## Impact

- Skills: `skills/groma/SKILL.md` (interview, a commit step before the summary), `skills/groma-agents` (Git workflow section conditional), `skills/groma-loop/SKILL.md` (git off), `skills/groma-lay-out/scripts/docs-impact.sh` and its vendored copies (`scripts/sync-shared.sh`), new `references/gitignore.md` in the groma skill, `templates/config.yaml`, `groma-methodology` config validation for `git.enabled`.
- CLI: `cli/init.js`, `cli/answers.js`, `cli/config.js` and their tests.
- Tests: bats for repository setup, `.gitignore`, first commit (with and without identity, parent repository) and docs-impact outside git; CLI unit tests; the `empty` eval fixture's assertions where they check git state.
- The never-overwrite rule (ADR 0006) holds: `git init` adds `.git/`, `.gitignore` is written only when absent, and a commit records files without changing them.
