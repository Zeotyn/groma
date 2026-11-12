# Git integration strategies

Single source of the integration procedure behind `git.integrate` in `.groma/config.yaml`. groma-agents writes the row of the configured strategy into the "Git workflow" section of AGENTS.md; groma-loop runs the procedure when it archives a change; `tests/scripts/git-integrate.bats` runs this file.

## Placeholders

| Placeholder | Meaning |
|---|---|
| `<main>` | the main branch, see "Main branch" |
| `<branch>` | the change branch, named after the change (`c007-cache`) |
| `<change-id>` | the change name |
| `<type>` | the conventional-commit type of the change type: `c` feat, `f` fix, `d` docs, `r` refactor, `m` and `s` chore |
| `<proposal title>` | the change title as groma-loop's `methodology-adapters.md` defines it per methodology |
| `<message file>` | a file holding the commit message, for example `<change>/reviews/.commit-msg`, deleted after the commit; messages never go through `-m`, so quotes, backticks and `$` in titles are safe |
| `<main worktree>` | the worktree in which `<main>` is checked out when that is not this one, see "Linked worktrees" |

## Main branch

One rule for every script and skill (`git-practice.sh`, `docs-impact.sh`, groma-loop, groma-agents); the first that exists wins:

1. the remote's default branch: `git symbolic-ref --short refs/remotes/origin/HEAD` without `origin/`
2. `main` (`refs/heads/main`)
3. `master` (`refs/heads/master`)
4. `main` as a remote-only branch (`refs/remotes/origin/main`)
5. the current branch (`git symbolic-ref --short HEAD`); the read-only scripts use `HEAD` when it is detached

A name without a local branch (cases 1 and 4) is read through `refs/remotes/origin/<main>` by the read-only scripts. groma-loop integrates only into a local `<main>`: in cases 4 and 5 it escalates and asks which branch is the main branch before it branches or integrates.

## Strategies

| Strategy | Commands | On conflict | Result on `<main>` |
|---|---|---|---|
| rebase | `git rebase <main> <branch>` then `git switch <main>` then `git merge --ff-only <branch>` | `git rebase --abort` | the branch commits in a straight line, no merge commit |
| merge | `git switch <main>` then `git merge --no-ff <branch>` | `git merge --abort` then `git switch <branch>` | one merge commit on top of the branch commits |
| squash | `git switch <main>` then `git merge --squash <branch>` then `git commit -F <message file>` | `git reset --merge` then `git switch <branch>` | one commit named after the change (`<type>(<change-id>): <proposal title>`; with `commits: free` `<change-id>: <proposal title>`); the branch keeps its commits |

`git reset --merge` is the squash abort because `git merge --squash` writes no `MERGE_HEAD`, so `git merge --abort` refuses.

## Procedure

Before the row:

1. **Clean trees.** HEAD is on `<branch>` (not detached), `git status --porcelain` prints nothing here and, in the worktree case, in `<main worktree>`. Otherwise stop and escalate; nothing has run.
2. **Record the refs.** `git rev-parse <main> <branch>`. After an abort both must print the same again.
3. **Fresh main.** When a remote exists, `git fetch`. When `<main>` has an upstream (`git rev-parse -q --verify <main>@{u}`): behind and not ahead (`git rev-list --count <main>..<main>@{u}` above 0 and `git rev-list --count <main>@{u}..<main>` equal to 0) → `git switch <main>`, `git merge --ff-only <main>@{u}`, `git switch <branch>` (worktree case: `git -C <main worktree> merge --ff-only <main>@{u}`); diverged (both above 0) → escalate: "run `git pull --ff-only` on `<main>` yourself, then rerun".

Then the row's commands in order. The first command that fails stops the sequence:

- conflicting paths exist (`git diff --name-only --diff-filter=U` in the worktree where the command ran prints paths): note the paths, run the row's abort commands, check the recorded refs, escalate with the paths;
- no conflicting paths (for example "nothing to commit" when the branch is already integrated, a refused fast-forward, a failing hook): do not run the abort; escalate with git's output and the current branch.

After the row `<main>` holds the change. Push only by `git.push`: `git push` on `<main>`, never with `--force` or `--force-with-lease`; a rejected push is escalated, not retried.

## Linked worktrees

When `<main>` is checked out in another worktree (`git worktree list --porcelain` has a block with `branch refs/heads/<main>` whose `worktree` path is not `git rev-parse --show-toplevel`), `git switch <main>` would fail. Then:

- every command of the row except `git rebase …` runs as `git -C <main worktree> …`, and `git switch <main>` and `git switch <branch>` are dropped, because neither worktree changes its branch;
- the abort commands of merge and squash run as `git -C <main worktree> …` too; `git rebase --abort` runs here;
- `<main worktree>` must be clean before anything runs (step 1); otherwise escalate.

## Never

- `--force`, `--force-with-lease`, `git push -f`
- `git branch -f <main>`, `git update-ref` on `refs/heads/<main>`, `git reset --hard` on `<main>`: `<main>` moves only through the row's merge or fast-forward
- `git branch -d` or `-D`: branches stay after integration
- rewriting a commit that is on `<main>`: the rebase row rewrites only `<branch>`, whose commits are not on `<main>` yet
- resolving a conflict: a person does that after the abort

A request to "merge" a branch means the configured row, not `git merge` as such.
