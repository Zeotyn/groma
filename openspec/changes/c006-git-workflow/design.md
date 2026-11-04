## Context

groma-loop runs changes end to end but stops short of git: it records `git rev-parse HEAD` as the review base and nothing else. Branching, committing and integrating are done by whoever drives the agent: the user, or an orchestrator such as herdr that sends "merge branch X into main". Agents read AGENTS.md, not `.groma/config.yaml`, so a setting only in the config would not reach them. Constraints: additive writes for setup (ADR 0006), POSIX sh scripts (ADR 0005), no force-push (already an escalation in groma-loop). This repository wants rebase plus fast-forward, no PRs, push only when asked.

## Goals / Non-Goals

**Goals:**
- One setting decides integration, and every agent follows it, including agents that are not running groma-loop.
- groma-loop performs the git steps safely and escalates instead of resolving conflicts.
- Brownfield projects keep their existing practice by default.

**Non-Goals:**
- Pull requests, hosting APIs (`gh pr create`), reviews on the forge.
- Commit signing, hooks, branch protection.
- Resolving merge or rebase conflicts automatically.
- Worktree management (orchestrators like herdr do that).

## Decisions

### D1: AGENTS.md carries the rule, the config is its source
groma-agents renders a "Git workflow" section from `git` settings, including the sentence "A request to merge a branch means: <strategy commands>". That reaches every agent and every orchestrator-driven session. The config stays the single source; re-running groma regenerates the section only in an AGENTS.md that groma created, and existing files get a snippet (ADR 0006).

Alternatives: config only, read by groma-loop (rejected: agents outside the loop never see it, which is how `47bf191` happened); a git hook that rejects merge commits (rejected: outside groma's write scope and invisible to agents until it fails).

### D2: Three strategies with fixed command sequences
- `rebase`: `git rebase <main> <branch>`, then `git switch <main>` and `git merge --ff-only <branch>`.
- `merge`: `git switch <main>`, then `git merge --no-ff <branch>`.
- `squash`: `git switch <main>`, then `git merge --squash <branch>`, then `git commit` with subject `<type>(<change-id>): <proposal title>`.

The main branch is `git symbolic-ref refs/remotes/origin/HEAD`, else `main`, else `master`.

Alternatives: free-form strategy text in the config (rejected: not testable, and agents interpret it differently); `rebase` without fast-forward, leaving integration to the user (rejected: the user asked groma-loop to do it fully).

### D3: Safety by abort-and-escalate
Any conflicting rebase or merge is aborted (`git rebase --abort` or `git merge --abort`), so both refs are unchanged, and then escalated with the conflicting paths. A rejected push escalates. A dirty tree at start escalates before branching, with the option to continue without git steps. groma never deletes branches and never force-pushes. Rebasing rewrites only the change branch, which is not on the main branch yet.

Alternatives: let the agent resolve conflicts (rejected: silent semantic merges are the riskiest step in the whole flow); stash the dirty tree automatically (rejected: hides the user's work in a stash they may not notice).

### D4: History-based recommendation by script
`skills/groma-detect/scripts/git-practice.sh [dir]` reads `git log --first-parent -200 <main>` and prints:
- `integrate<TAB><value><TAB><evidence>`
- `commits<TAB><value><TAB><evidence>`

Rules, in order:
1. `merge` when there are at least 5 merge commits and at least half of them are "Merge pull request" or "Merge branch" commits.
2. `squash` when at least half of the subjects end in `(#<n>)` and there are fewer than 5 merges.
3. `rebase` otherwise.

The conventional-commit regex is `^(feat|fix|docs|chore|refactor|test|ci|build|perf|style|revert)(\(.+\))?!?: `. The `commits` value is `conventional` when at least 70 percent of subjects match it.

Alternatives: let the agent read the log and decide (rejected: not repeatable, and groma's other detectors are scripts); ask without a recommendation (rejected: every interview question needs a recommended default).

### D5: One commit per review unit
After a unit's tests pass and its review stops clean, groma-loop stages exactly the files the unit changed (from `git status --porcelain`, minus files that were dirty at start, which cannot exist after D3) and commits them. The subject comes from the task-group title in the configured style, for example `feat(c007-cache): add cache layer`. The archive gets its own commit, `docs(openspec): archive <change-id>`.

Alternatives: one commit per change (rejected: loses the review-unit history that reviews refer to); one commit per task (rejected: noisy, and tasks inside a group are reviewed together).

## Risks / Trade-offs

- [Rebase changes commit hashes that review records mention] → records cite files and task ids, not hashes. The base is recomputed with `merge-base`.
- [The change branch was pushed earlier, so the rebase diverges it from its remote] → groma pushes only the main branch. A diverged remote change branch stays as it is, because force-pushing is forbidden, and the summary mentions it.
- [The heuristics misread mixed histories] → evidence is shown in the interview, and the user picks.
- [Orchestrators ignore AGENTS.md] → nothing groma can enforce. The rule is as visible as possible, and groma-loop itself complies.

## Migration Plan

- Validator accepts `git`. A missing section means the defaults.
- `upgrades.md` row 0.3.0: offer the git question in update mode, regenerate the AGENTS.md section only when groma created the file, and otherwise add a snippet to the findings report.
- C004's docs-impact base switches to `merge-base` on change branches. The proposal-commit rule stays as the fallback.

## Open Questions

- Should `push: auto` also push the change branch, for backup? Deferred: pushing only the main branch keeps the no-force rule simple.
