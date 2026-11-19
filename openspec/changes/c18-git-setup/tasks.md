## 1. Tests first

- [x] 1.1 Bats fixtures and tests for the repository offer: empty folder outside git (yes and no), brownfield folder outside git (no recommended), parent work tree named and asked, `git init` fallback when `-b` is rejected (stub git)
- [x] 1.2 Bats tests for the first commit: with identity (one commit, clean tree, message), without identity (no commit, next action), repository with history (no question, no commit), `.gitignore` honoured
- [x] 1.3 Bats tests for `docs-impact.sh` outside git and before the first commit: `note` line, part (b) still reported, `--gate` exit 0 and 4
- [x] 1.4 Structure check: `git.enabled` in the config template and accepted by config validation; `references/gitignore.md` vendored byte-identical where it is read (only the groma skill and the CLI, through `skills/groma/scripts/git-init.sh`, read it, so there is no copy to vendor)

## 2. Skill

- [x] 2.1 `skills/groma/references/gitignore.md`: stack rows and the `all` rows; vendor it with `scripts/sync-shared.sh` (no consumer outside the groma skill, so no entry)
- [x] 2.2 A small script in `skills/groma/scripts/` that sets up the repository (`git init -b main` with fallback, `.gitignore` only when absent) and one that makes the first commit by D2 (identity check, `git commit -F`), both printing one result line
- [x] 2.3 `skills/groma/SKILL.md`: repository question in the interview (D1, parent repository), first-commit step before the summary (D2), `git.enabled: false` on no; config template gets `enabled: true`
- [x] 2.4 `groma-methodology` config validation knows `git.enabled` (boolean)
- [x] 2.5 `groma-agents`: no "Git workflow" section when `git.enabled: false`; `groma-loop`: git off skips every git step and says so once
- [x] 2.6 `docs-impact.sh`: outside git or without a commit, report part (b) with a `note`, exit 0 or 4 by the gate; sync the vendored copies

## 3. CLI

- [x] 3.1 CLI unit tests first: `--git init|skip`, `--commit yes|no`, `--yes` recommendations for greenfield and brownfield, no question inside a repository
- [x] 3.2 `cli/init.js`, `cli/answers.js`, `cli/config.js`: the repository question and the first commit through the same scripts as the skill
- [x] 3.3 `scripts/test.sh` green; `openspec validate --all --strict`; style drift 0

## 4. Docs

- [x] 4.1 `docs/concept.md` (repository offer, first commit), `docs/architecture.md` (scripts, reference table, CLI path), `docs/data-model.md` (`git.enabled`)
- [x] 4.2 ADRs for D1 to D4 (proposed, `origin: c18-git-setup#D<n>`), `docs/adr/README.md`
- [x] 4.3 `skills/groma/references/upgrades.md` row for the next version; CHANGELOG `[Unreleased]`
- [x] 4.4 `sh skills/groma-lay-out/scripts/docs-impact.sh --root . --gate openspec/changes/c18-git-setup` prints `impact=0 adr=0`, or a `Docs: <path> unchanged, because <reason>` line per doc it names
- [x] Docs: `docs/glossary.md` unchanged, because the change adds no new term (repository, first commit and `git.enabled` are plain words or config keys described in concept and data model)
- [x] Docs: `docs/vision.md` unchanged, because the README only gained the `--git` and `--commit` flags, not a change of purpose or audience

## 5. Review round 1

- [x] 5.1 SC2015 in `git-init.sh` and `first-commit.sh` rewritten as `if`; both scripts are only read by the groma skill and the CLI, so nothing to re-sync (`sync-shared.sh --check` differs=0)
- [x] 5.2 Git off is tested by the structure check `git-off` (`tests/structure/check.py` `check_git_off`, pytest cases in `test_check.py`): groma-agents SKILL.md has a rule that drops the Git workflow section on `git.enabled: false`; groma-loop SKILL.md has a rule that skips every git step on `git.enabled: false` and says "git steps skipped (git.enabled: false)"; the AGENTS.md template with its `## Git workflow` section dropped has no "Git workflow" text and stays within 80 lines and 3200 chars. The agent's rendering itself stays covered only by evals (costs tokens)
- [x] 5.3 CLI stack rows: the CLI has no stack question, so `git-init.sh` selects stack rows by the manifests at the project root; CLI test `the CLI has no stack question: .gitignore rows come from the manifests at the project root`; recorded in ADR 0075, `docs/architecture.md`, design D1 and the cli delta spec
- [x] 5.4 CLI parent repository: the CLI asks use or init (`--git use|init`, `use` recommended, `--git skip` there and `--git use` outside git are usage errors); `init` sets up an own repository and offers the first commit; CLI tests for the question, the flag and the usage errors; README, ADR 0075, architecture, CHANGELOG and the cli delta spec updated
- [x] 5.5 ADR 0076 states the non-TTY fallback: without a TTY and without `--yes` the CLI takes the recommended answers for `git` and `commit` and says so in its `No TTY` note
- [x] 5.6 `git-init.sh --check` prints `state missing recommend=skip` without git on PATH, `git-init.sh` exits 1 with "git not found on PATH"; `first-commit.sh` prints `commit no-git` and exits 1; bats tests for both; `/groma` asks no git question on `state missing`
- [x] 5.7 ADR 0076 states that the identity check reads `git config user.name/user.email` only and ignores `GIT_AUTHOR_*` and `GIT_COMMITTER_*`
