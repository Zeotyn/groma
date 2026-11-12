## Context

About 30 `../groma-*/` references across seven skills (see proposal). `npx skills` installs skill folders only, so a skill's own folder is all it can rely on.

## Goals / Non-Goals

**Goals:**
- Every skill installed alone passes its standalone test.
- One source of truth per shared file; drift between copies fails CI.

**Non-Goals:**
- Merging skills or changing what they do.
- Removing procedure hand-offs between skills (the orchestrator still loads sub-skills).

## Decisions

### D1: Vendored copies with a sync script and a drift check
A manifest `scripts/shared-files.txt` lists `source -> consumer/path` pairs. `scripts/sync-shared.sh` copies sources to consumers; `check.py` compares bytes and fails on a difference, naming the pair. Contributors edit only the source.

Alternatives: a shared `groma-common` skill that every skill depends on (rejected: `npx skills --skill X` would not pull it in, the same breakage); symlinks (rejected: break on Windows and in npm tarballs); degrade when the sibling is missing (rejected: features silently disappear, and the README promise stays false).

### D2: Procedure hand-offs stay, with a message when the sibling is missing
When a skill delegates a whole step to another skill (groma → groma-survey), it keeps the reference and, if the sibling is absent, tells the user which skill to add and skips that step.

## Risks / Trade-offs

- [Copies drift when someone edits a consumer] → the drift check fails CI and names the source to edit.
- [Package size grows] → shared files are small tables; measure the tarball before and after.

## Implementation notes

- **Hand-off list.** The allowed sibling references live in `scripts/handoffs.txt` (`<skill file> <reference>`), read by `check.py handoffs` and `tests/scripts/standalone.bats`. Besides "follow `../groma-<name>/SKILL.md`" (groma's eight steps, groma-loop's ADR candidates via groma-lay-out), two kinds stay as hand-offs, because vendoring them would change the full suite's behavior: groma-agents writes the paths of groma-methodology's `status.sh`, `next.sh`, `next-stop.sh` and groma-lay-out's `docs-impact.sh` into AGENTS.md and hook files (the project's agents must run the sibling's installed copy), and groma-loop runs groma-methodology's `roadmap.sh` after archive (the roadmap belongs to the change naming that groma-methodology sets up). Each names `npx skills add Zeotyn/groma --skill <name>` and skips when the sibling is missing (D2).
- **`install.md` split.** groma-lay-out only needs the consent flow of groma-skills' `references/install.md`, and a copy of the whole file would carry a link to `../agents.yaml` that groma-lay-out does not have. The "Asking first" and "When commands cannot run" sections moved unchanged into `skills/groma-skills/references/install-consent.md`, which is vendored into groma-lay-out; `install.md` links to it.
- **19 copies.** groma: `code-style-tools.md`, `style-drift.sh`, `git-practice.sh`, `catalog.yaml`, `templates/AGENTS.md`; groma-survey: `detect.sh`, `signals.md`, `doc-slots.md`, `code-style-tools.md`, `adr-template.md`; groma-skills: `agents.yaml`, `validate-config.sh`; groma-agents: `agents.yaml`, `naming-rule.md`; groma-lay-out: `install-consent.md`; groma-methodology: `check-prereqs.sh`, `docs-impact.sh`; groma-loop: `docs-impact.sh`, `git-strategies.md`. `style-drift.sh` reads `$HERE/../references/code-style-tools.md` and `status.sh` reads `$HERE/docs-impact.sh`, so source and copies work in every folder.
- **Fallbacks for a missing sibling file removed**, since the file is now always local: survey's "else `find` yourself" and "MADR 4.0 from memory", groma's "drop `--catalog`", groma-skills' "when groma is installed" and install.md's "if agents.yaml is missing", groma-agents' "else the template text" for change naming, groma-loop's "table missing: AGENTS.md section" and "groma-lay-out missing: skip the check". With the full suite installed nothing changes; installed alone, these skills now behave like the full suite instead of degrading.
- **groma-loop without groma-lay-out**: the docs gate runs from its own `docs-impact.sh`; `impact` lines count as findings, `adr` lines are left out (writing ADR candidates is groma-lay-out's procedure) and the user is told to add groma-lay-out. `strict` escalates only on `impact` lines then.
- **Message text.** `style-drift.sh`'s note for a missing table now says "(code-style-tools.md missing)" instead of "(groma-lay-out missing)", since the table is no longer looked up in groma-lay-out; reachable only with `--table` pointing at a missing file. `tests/scripts/style-drift.bats` follows.
- **`sync-shared.sh --check`** reports differing copies without copying (exit 1); not required by D1, handy before a commit. `tests/scripts/sync-shared.bats` covers the script.
- **Tests-first commit** is red on purpose (standalone and structure checks fail until the refactor commit).
- **ADR 0033** says groma-survey reads the style table through `../groma-lay-out/references/`; ADR 0051 refines that detail instead of editing an accepted ADR.
- **Review fixes (Sonnet review).** The rule text of groma-methodology's `conventions.md` moved into its own `naming-rule.md`, the file groma-agents now carries, so the copy names no scripts groma-agents lacks. groma-skills and groma-agents create a minimal findings report (title plus their section) when the run has none, instead of relying on groma-survey's template. `doc-slots.md` and the AGENTS.md template name groma-survey's ADR sources and groma-methodology's `next-change-id.sh` as "when installed". `check.py handoffs` also requires `npx skills add Zeotyn/groma --skill <sibling>` in the hand-off's file; groma's SKILL.md passes with its generic `--skill <name>` line, which covers all of its sibling steps. groma-loop's strict gate without groma-lay-out reads the `summary` line instead of the exit code.
