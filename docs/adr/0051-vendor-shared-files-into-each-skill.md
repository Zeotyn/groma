---
status: proposed
date: 2026-11-12
decision-makers: Eugen Waldschmidt
evidence: [scripts/shared-files.txt, scripts/sync-shared.sh, scripts/handoffs.txt, tests/structure/check.py, tests/scripts/standalone.bats]
origin: r001-vendor-shared-files#D1
---

# Vendor shared files into each skill, kept identical by a sync script and a check

## Context and Problem Statement

The README promises that every skill works on its own, and `npx skills add Zeotyn/groma --skill <name>` installs one skill folder only. The skills read about 30 files in sibling folders (`../groma-lay-out/references/code-style-tools.md`, `../groma/agents.yaml`, `../groma-agents/references/git-strategies.md`, ...). Installed alone, groma-survey cannot find its style table and groma-loop cannot find its git strategies; only groma-detect has no sibling dependency. How does a skill get the shared tables, templates and scripts it reads, without each copy drifting?

## Decision Drivers

* A skill installed alone has nothing but its own folder
* One source of truth per shared file
* Works in npm tarballs, plugin caches and on Windows
* No behavior change for the full suite

## Considered Options

* Vendored copies listed in a manifest, a sync script and a byte-compare structure check
* A shared `groma-common` skill that every skill depends on
* Symlinks from consumers to the source
* Degrade when the sibling is missing

## Decision Outcome

Chosen option: "vendored copies listed in a manifest, a sync script and a byte-compare structure check", because it is the only option that makes a single installed folder complete while keeping one file to edit.

Details:
- `scripts/shared-files.txt` lists `<source> -> <consumer>` pairs. Contributors edit only the source and run `scripts/sync-shared.sh`, which copies sources over consumers (`--check` reports differences).
- `tests/structure/check.py shared` fails when a copy differs from its source and names the source to edit.
- Skills read their local copy (`references/...`, `scripts/...`, `templates/...`). A procedure hand-off, where a skill follows another skill's `SKILL.md`, runs a sibling's procedure or writes a sibling's script path into project files, stays a `../groma-<name>/` reference; it is listed in `scripts/handoffs.txt`, names the `npx skills add Zeotyn/groma --skill <name>` command and skips the step when the sibling is missing. `check.py handoffs` fails on any other sibling reference and on a hand-off whose file lacks that command.
- `tests/scripts/standalone.bats` copies each skill folder alone into a temporary project and runs its reference check and scripts.
- `scripts/` is not shipped; the copies inside `skills/` are what the npm package, the plugins and `npx skills` deliver.

### Consequences

* Good, because every skill installed alone finds the files it reads.
* Good, because a drifted copy fails CI with the source to edit.
* Bad, because the package carries duplicate files: the npm tarball grew from 95,327 to 99,009 bytes (279,110 to 379,692 unpacked, 96 to 117 files).
* Bad, because contributors must remember the sync step; the check catches it.

### Confirmation

`scripts/test.sh` runs `check.py shared` and `check.py handoffs`, `tests/scripts/standalone.bats` and `tests/scripts/sync-shared.bats`.

## Pros and Cons of the Options

### A shared `groma-common` skill

* Bad, because `npx skills add --skill <name>` does not pull in a dependency, so a skill installed alone breaks the same way.

### Symlinks

* Bad, because they break on Windows, in npm tarballs and when a plugin is fetched from git into the cache.

### Degrade when the sibling is missing

* Bad, because features silently disappear and the README promise stays false.

## More Information

Refines ADR 0033, whose table groma-survey now reads from its own copy instead of `../groma-lay-out/references/`. Decision D1 of `openspec/changes/r001-vendor-shared-files/design.md`.
