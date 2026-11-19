## Context

`/groma` step 2 asks the git questions only inside a work tree (`skills/groma/SKILL.md`, "Outside git: ask nothing and keep the defaults"). Outside git, the run still writes `git` defaults and an AGENTS.md "Git workflow" section, and the project breaks later: `docs-impact.sh` exits 2 without a repository with commits, so the docs gate of the first change cannot run, and groma-loop drops its git steps. `npx groma-cli init` has no git question at all. The never-overwrite rule (ADR 0006) and the consent rule for actions with side effects (ADR 0035) apply.

## Goals / Non-Goals

**Goals:**
- A greenfield folder without git ends a groma run as a repository on `main` with one commit and a clean tree, when the user agrees.
- A project that declines git gets a consistent setup: no git section, no git steps, a docs gate that still works.
- `/groma` and `npx groma-cli init` give the same project.

**Non-Goals:**
- Creating a remote or pushing (hosting choice, credentials).
- Setting a git identity for the user.
- Changing an existing repository's history, branch names or ignore file.

## Decisions

### D1: Offer the repository in the interview, recommended for greenfield only

The repository question comes right before the integration strategy question, so the existing questions follow when the answer is yes. Greenfield recommends yes; brownfield recommends no, because a folder with code but without `.git/` was usually copied out of a repository somewhere else, and a second history would split it. A folder inside a parent work tree (for example a dotfiles repository in the home folder) is detected by comparing `git rev-parse --show-toplevel` with the project folder; groma names the top level and asks, using it is the recommended option. `git init` uses `-b main` (git 2.28 or newer); with an older git, groma runs `git init` and `git symbolic-ref HEAD refs/heads/main`. The CLI asks the same question (`--git init|skip`).

Alternatives: always `git init` without asking (lost: running a command with lasting side effects in the user's folder without consent contradicts ADR 0035); a hint in the summary only (lost: the user has to leave the flow, and the docs gate of the first change still breaks); recommend yes for brownfield too (lost: a copied codebase would get a history detached from its origin).

### D2: Offer the first commit before the summary, only for a repository without commits

The commit closes the run, after agents and skill copies, so it records every file the run wrote. It is offered only when the repository has no commit (`git rev-parse --verify HEAD` fails): groma just created it, or the user ran `git init` without committing. It stages what `git status --porcelain` lists, which in such a repository is the whole project, honours `.gitignore`, and commits with `git commit -F <file>` and the message `chore: set up project with groma <version>`, the user's identity, no `--no-verify`. No identity means no commit and a next action that names `git config user.name`, `git config user.email` and the commit command.

Alternatives: commit only groma's files (lost: in a new repository the user's few files would stay untracked and the tree would not be clean, which groma-loop requires); commit after every step (lost: noise in a history that has not started yet); offer a commit in repositories with history too (lost: groma would commit into an existing history it did not start, which groma-loop does per change with its own rules).

### D3: `.gitignore` from a stack reference table, only when absent

Ignore rules are stack knowledge, so they live in `skills/groma/references/gitignore.md` as rows of stack and pattern, with a stack `all` for editor and OS files (`.DS_Store`, `Thumbs.db`, `*.swp`); the skill and the CLI read the same table (vendored by `scripts/sync-shared.sh`). The file is written only when groma set up the repository in this run and no `.gitignore` exists.

Alternatives: no `.gitignore` (lost: the first commit would include `node_modules/` or `.venv/` when the user installed before running groma); fetch templates from github/gitignore (lost: network access and an external source at setup time); let the agent write one freely (lost: stack logic in skill text, different results per run and per entry point).

### D4: `git.enabled: false` turns git off consistently

A declined repository is recorded as `git.enabled: false`, defaulting to `true` so existing configs keep their meaning. groma-agents leaves out the "Git workflow" section, groma-loop skips git steps without asking (it says so once in its summary), and `docs-impact.sh` reports part (b), the ADR candidates, with a `note` that changed paths need git history, instead of exiting 2. The same `note` path covers a repository before its first commit, so the gate works from the first change on.

Alternatives: keep the defaults and let each step discover the missing repository (lost: AGENTS.md describes a git workflow that does not exist, and the gate fails with exit 2); a separate `vcs: none` key (lost: a second place for git settings next to the `git` section).

## Risks / Trade-offs

- [The user's global git config has hooks or signing that fail the commit] → the commit's error is reported unchanged, no retry with other flags; the summary's next action is to commit by hand.
- [A project folder on a network or synced drive where `.git/` is unwanted] → the question has a no option, and brownfield recommends no.
- [The parent-repository check misreads a submodule or a worktree] → groma only asks in that case and never runs `git init` without a yes.
- [`git init -b` missing in old git] → fallback with `symbolic-ref`, tested in bats with a stub that rejects `-b`.

## Migration Plan

`git.enabled` defaults to `true`, so existing configs need nothing. The upgrade note for the next version in `skills/groma/references/upgrades.md` says that a re-run asks nothing new in a repository, and offers the repository in a project without git whose config has no `git.enabled`.

## Open Questions

None.
