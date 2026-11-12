# Contributing to groma

Thanks for helping. Most changes do not need any skill logic: groma keeps stack knowledge in tables.

## Quick start

```sh
npx --yes @fission-ai/openspec@1.16.0 init --tools claude,github-copilot --no-animation --no-copilot-cloud .
```

This regenerates the OpenSpec contributor skills, which are git-ignored so that `npx skills add` on this repository only offers groma's own skills.

```sh
scripts/test.sh          # structure + script tests (needs: git, sh, node/npx, uv)
scripts/test.sh evals    # agent evals, needs ANTHROPIC_API_KEY and costs tokens
```

## Common contributions

### Add a stack pattern (data model, ADR or doc locations)

1. Add one row to the matching table:
   - data model sources: `skills/groma-survey/references/data-sources.md`
   - ADR locations: `skills/groma-survey/references/adr-sources.md`
   - greenfield/brownfield signals: `skills/groma-detect/references/signals.md`
2. Optional: add a small fixture under `tests/fixtures/` (see `tests/fixtures/generate.sh`).
3. Run `scripts/sync-shared.sh` (groma-survey carries a copy of `signals.md`), then `scripts/test.sh`.

### Add a skill to the catalog

1. Add an entry to `skills/groma-skills/catalog.yaml` under the right category.
2. Pin `ref` to a tag or commit of the upstream repository.
3. Run `scripts/sync-shared.sh` (groma carries a copy of the catalog), then `scripts/test.sh` (the catalog validator runs as part of it).

### Edit a file that several skills share

Some tables, templates and scripts are vendored into every skill that reads them, so that each skill works when installed alone (ADR 0051). `scripts/shared-files.txt` lists each source and its copies.

1. Edit the source, never a copy (the first path of its line in `scripts/shared-files.txt`).
2. Run `scripts/sync-shared.sh`; `scripts/sync-shared.sh --check` lists copies that differ.
3. Run `scripts/test.sh`. The structure check fails on a differing copy and names its source.

A skill that needs a new file from a sibling gets a copy: add a `<source> -> <copy>` line and run the sync. Do not write `../groma-<name>/` paths into a skill; only procedure hand-offs (following another skill's `SKILL.md`) may, listed in `scripts/handoffs.txt` with a message that names the skill to add when it is missing.

### Add a fixture

Fixtures are generated, not committed as git repositories. Extend `tests/fixtures/generate.sh` so the history is deterministic (fixed dates and author).

### Add a reviewer CLI

Reviewer commands live in `skills/groma-loop/scripts/review.sh` (`call()`), the auto order in `resolve-reviewer.sh`. Add the agent to both, to the validator's reviewer list in `skills/groma/scripts/validate-config.sh`, and a stub test in `tests/scripts/review.bats`. Reviewers must run headless and read-only.

## CLI development

The CLI lives in `bin/` and `cli/`. It is ESM, needs Node >= 22 and has one runtime dependency, `yaml` (pinned). The data files `skills/groma/agents.yaml` and `skills/groma-methodology/methodologies.yaml` are shared with the skills; edit them there, not in `cli/` (and not in the vendored copies of `agents.yaml` in groma-skills and groma-agents).

```sh
node --test 'cli/test/*.test.js'     # CLI tests
scripts/test.sh cli                  # same, plus npm pack contents check
node bin/groma.js init --dry-run --yes <dir>
```

## Change workflow

groma is built with [OpenSpec](https://github.com/Fission-AI/OpenSpec) and follows its own naming convention: `<type><NNN>-<slug>` with types `m` milestone, `c` change, `f` fix, `s` spike, `r` refactor, `d` docs.

```sh
skills/groma-methodology/scripts/next-change-id.sh c      # prints the next free change id, e.g. c002
openspec new change "c002-your-slug"
```

Larger changes run through `groma-loop` so a second model reviews the proposal and every task group.

## Rules that every PR must keep

- groma never modifies, moves or deletes a file that existed before a run. The invariant test enforces this.
- No database connections. Data models come from files in the repository or from a dump the user creates.
- Shell scripts are POSIX `sh` and pass `shellcheck`.
- Every skill works installed alone: shared files are vendored copies kept identical by `scripts/sync-shared.sh`.
- Plugin manifests and `CHANGELOG.md` carry the same version.
