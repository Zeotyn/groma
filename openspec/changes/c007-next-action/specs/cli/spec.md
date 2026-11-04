## ADDED Requirements

### Requirement: Next command
`groma next [path]` SHALL run the next-action script with `--long` by default and pass `--short` and `--json` through, with exit code 0 also when nothing is printed.

#### Scenario: Terminal use
- **WHEN** the user runs `npx groma-cli next` in a project with 3 unpushed commits
- **THEN** it prints "Push 3 commits on main: git push"
