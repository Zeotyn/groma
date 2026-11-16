## MODIFIED Requirements

### Requirement: Output formats
`--short` SHALL print at most 20 characters without a trailing newline problem for status lines, for example `push 3` or `verify c007`. `--long` SHALL print one sentence with the exact command, for example "Push 3 commits on main: git push". When the command is an OpenSpec workflow step, `--long` SHALL use the command form of the OpenSpec generation installed in the project. `--json` SHALL print the rung id, the short and the long text.

#### Scenario: Short form
- **WHEN** rung 3 applies to `c007-cache` in a project with OpenSpec 1.x
- **THEN** `--short` prints `verify c007` and `--long` prints "c007-cache: all tasks done, verify: /opsx:verify c007-cache"

#### Scenario: OpenSpec 2.x command form
- **WHEN** rung 8 applies to `c7-work` with 1 of 3 tasks done, and the project has `.agents/skills/openspec-apply-change/` but no `opsx` command folder
- **THEN** `--long` prints "c7-work: 1/3 tasks, continue: /openspec-apply c7-work"

#### Scenario: Generation unknown
- **WHEN** rung 3 applies to `c7-work` and the project has `openspec/changes/` but neither an `opsx` command folder nor OpenSpec skills
- **THEN** `--long` prints "c7-work: all tasks done, verify, then archive" without a slash command
