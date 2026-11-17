## 1. Tests

- [ ] 1.1 `tests/scripts/skill-source.bats` with a temporary `HOME` and `CLAUDE_CONFIG_DIR`: no skills folder, symlink into the checkout, symlink into another checkout, foreign real folder, override variable, non-groma skills ignored, `CLAUDE_CONFIG_DIR` wins over `HOME`

## 2. Check

- [ ] 2.1 `tests/evals/skill-source.sh <root>`: resolve each user-level `groma`/`groma-*` folder with `cd -P` and `pwd -P`, compare with `<root>/skills/<name>`, exit 3 with path and fix, warn and exit 0 under `GROMA_EVAL_ALLOW_USER_SKILLS=1`
- [ ] 2.2 `tests/evals/run.sh` runs the check before generating fixtures and before any `claude -p`; the header documents `GROMA_EVAL_ALLOW_USER_SKILLS`
- [ ] 2.3 `scripts/test.sh` green, shellcheck 0.10.0 clean

## 3. Docs

- [ ] 3.1 `docs/architecture.md`: one sentence on the skill-source check in the evals paragraph
- [ ] 3.2 `CHANGELOG.md`: Fixed entry under `[Unreleased]`
