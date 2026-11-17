## ADDED Requirements

### Requirement: Eval skill source
Before an eval run calls the agent, it SHALL check every user-level skill folder named `groma` or `groma-*` in the agent's user skills folder (`$CLAUDE_CONFIG_DIR/skills` when set, else `~/.claude/skills`). When one resolves, with symbolic links followed, to a path other than the same-named skill folder of the checkout under test, the run SHALL stop before any API call with exit code 3 and name the conflicting path and the fix. With `GROMA_EVAL_ALLOW_USER_SKILLS=1` the run SHALL print a warning and continue.

#### Scenario: Symlink into another checkout
- **WHEN** `~/.claude/skills/groma` is a symlink to `skills/groma` of another checkout and the evals start from a worktree
- **THEN** the run exits 3 before calling the agent and names `~/.claude/skills/groma` and how to fix it

#### Scenario: Symlink into the checkout under test
- **WHEN** every user-level groma skill resolves into `skills/` of the checkout under test
- **THEN** the check passes silently and the evals run

#### Scenario: Override
- **WHEN** a user-level groma skill points elsewhere and `GROMA_EVAL_ALLOW_USER_SKILLS=1` is set
- **THEN** the run prints a warning naming the path and continues
