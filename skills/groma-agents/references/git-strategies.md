# Git integration strategies

Single source of the command sequences behind `git.integrate` in `.groma/config.yaml`. groma-agents writes the row of the configured strategy into the "Git workflow" section of AGENTS.md; groma-loop runs that row when it archives a change. Placeholders: `<main>` is the main branch (the remote's default branch from `git symbolic-ref refs/remotes/origin/HEAD`, else `main`, else `master`), `<branch>` the change branch, `<change-id>` the change name, `<type>` the conventional-commit type of the change type (`c` feat, `f` fix, `d` docs, `r` refactor, `m` and `s` chore), `<proposal title>` the first heading or sentence of the proposal. With `commits: free` the squash subject is `<change-id>: <proposal title>`.

| Strategy | Commands | On conflict | Result on `<main>` |
|---|---|---|---|
| rebase | `git rebase <main> <branch>` then `git switch <main>` then `git merge --ff-only <branch>` | `git rebase --abort` | the branch commits in a straight line, no merge commit |
| merge | `git switch <main>` then `git merge --no-ff <branch>` | `git merge --abort` | one merge commit on top of the branch commits |
| squash | `git switch <main>` then `git merge --squash <branch>` then `git commit -m "<type>(<change-id>): <proposal title>"` | `git reset --merge` | one commit named after the change; the branch keeps its commits |

Rules for every strategy:

- A request to "merge" a branch means the configured row, not `git merge` as such.
- On a conflict run the abort command of the row, so `<main>` and `<branch>` point to the same commits as before, then stop and name the conflicting paths (`git diff --name-only --diff-filter=U`, read before the abort). Conflicts are resolved by a person.
- Never `--force` or `--force-with-lease`, never delete a branch, never rewrite a commit that is on `<main>`. The rebase row rewrites only `<branch>`, whose commits are not on `<main>` yet.
- Push only `<main>` (`git push`), and only when `git.push` allows it. A rejected push is reported, not retried with force.
