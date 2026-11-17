Milestone: m004

## Why

On 2026-11-17 an eval started from a git worktree tested the main checkout's skill text instead of the worktree's, and $3.63 went to testing the wrong code. `tests/evals/run.sh` passes `--plugin-dir "$ROOT"`, but Claude Code also loads user-level skills from `~/.claude/skills/` (or `$CLAUDE_CONFIG_DIR/skills`). On the maintainer's machine `~/.claude/skills/groma*` are symlinks into the main checkout, so those skills won over the worktree's, and the fixture's materialized `.claude/skills/groma/SKILL.md` carried the old text.

## What Changes

- New helper `tests/evals/skill-source.sh`: finds every user-level skill folder named `groma` or `groma-*` whose resolved path (symlinks followed) is not `$ROOT/skills/<same name>`. It exits 3 with a message that names each conflicting path and the fix (remove or relink it, or run from that checkout); with `GROMA_EVAL_ALLOW_USER_SKILLS=1` it only warns and exits 0. A user-level groma skill that resolves into `$ROOT/skills` passes.
- `tests/evals/run.sh` runs the helper before any fixture is generated or `claude -p` is called, so a wrong skill source costs no tokens. The header documents `GROMA_EVAL_ALLOW_USER_SKILLS`.
- Script tests for the helper with a temporary `HOME` and `CLAUDE_CONFIG_DIR`; no test calls `claude`.

The check aborts instead of pointing Claude Code at an isolated config folder, because the login lives in the user's config folder and an isolated one would need its own login.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `suite-testing`: evals refuse to start when a user-level groma skill would shadow the checkout under test.

## Docs impact

- `docs/architecture.md`: one sentence on the skill-source check in the evals paragraph of the runtime view.
- `CHANGELOG.md`: a Fixed entry under `[Unreleased]`.

## Impact

`tests/evals/run.sh`, new `tests/evals/skill-source.sh`, new `tests/scripts/skill-source.bats`. Nothing shipped in `skills/` changes.
