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
