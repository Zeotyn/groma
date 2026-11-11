---
status: proposed
date: 2026-11-11
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-detect/scripts/git-practice.sh, skills/groma/SKILL.md, tests/scripts/git-practice.bats, tests/fixtures/histories.sh]
origin: c006-git-workflow#D4
---

# Recommend the git workflow from the history by script

## Context and Problem Statement

Every interview question needs a recommended default. In a brownfield project the right default for `integrate` and `commits` is what the team already does, and that is visible in the git history. How does groma find it?

## Considered Options

* A read-only script, `skills/groma-detect/scripts/git-practice.sh`, reads the last 200 first-parent commits of the main branch and prints `integrate` and `commits` with evidence: `merge` when there are at least 5 merge commits and at least half of them are "Merge pull request" or "Merge branch" commits, `squash` when at least half of the subjects end in `(#<n>)` and there are fewer than 5 merges, `rebase` otherwise; `conventional` when at least 70 percent of the subjects match the conventional-commit form
* Let the agent read the log and decide
* Ask without a recommendation

## Decision Outcome

Chosen option: "a script with fixed rules", because it is repeatable, testable on fixture histories and consistent with groma's other detectors. An agent reading the log reaches different verdicts on different days, and a question without a recommended option breaks the interview rule. The evidence ("28 of 30 merges are pull-request merges") is shown with the recommendation, so a misread mixed history is corrected by the user, not hidden.

### Consequences

* Good, because brownfield projects keep their practice by default, and greenfield projects get `rebase` and `push: ask`.
* Good, because the rules are visible in the script header and covered by one bats test per rule.
* Bad, because the thresholds (5 merges, half, 70 percent) are heuristics; the interview shows the counts so the user can overrule them.

### Confirmation

`tests/scripts/git-practice.bats` on `tests/fixtures/histories.sh` (pull-request merges, squash subjects, linear conventional history, the 70 percent threshold, main-branch detection, empty repository).

## More Information

From design decision D4 of c006-git-workflow. The commit style counts the non-merge commits behind the merges, not only the first-parent line, so a pull-request project with conventional commits inside its branches is recognized; "Merge branch 'x' of <url>" subjects are pulls, not pull-request merges; fewer than 10 commits give the defaults with the counts (see the change's implementation notes). The main branch follows the one rule in `git-strategies.md` (remote default, `main`, `master`, remote-only `origin/main`, current branch), shared with `docs-impact.sh` and groma-loop. Related: ADR 0005, ADR 0007.
