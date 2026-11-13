---
status: proposed
date: 2026-11-13
decision-makers: Eugen Waldschmidt
evidence: [skills/groma/scripts/materialize.sh, cli/skills.js, tests/scripts/materialize.bats]
origin: c016-agent-only-init#D1
---

# Mirror the CLI's materialization rules in a shell script

## Context and Problem Statement

`groma init` and `groma update` copy the groma skills into each agent's project skill folder and track every copy by hash in `.groma/generated.json` (ADR 0018). The `/groma` skill could not do that: skills ship without `cli/`, and a plugin user may not have the npm package at all. So `/groma` sent the user to `npx groma-cli update` for every copy, and a project set up with the plugin alone gave a teammate who cloned it no groma skills. How does the agent path copy and refresh the skills with the same rules?

## Decision Drivers

* A plugin-only or `npx skills`-only user gets the same project result as a CLI user
* Deterministic: the same input gives the same files and the same `generated.json`
* No tokens spent on copying about a hundred files per agent
* Runs where the skills run: POSIX sh, no Node (ADR 0005)

## Considered Options

* A POSIX shell script `skills/groma/scripts/materialize.sh` that implements the plan of `planSkills` and `applySkills`, kept equal to the CLI by a parity test
* Let the agent copy the files itself
* Call the CLI's JavaScript from the skill
* Make the CLI call the shell script

## Decision Outcome

Chosen option: "a POSIX shell script that mirrors the CLI rules", because it is the only option that works without the npm package and stays deterministic.

Details:
- `materialize.sh [--update] [--dry-run] [--force] [--agents <a,b>] [--skills <s,t>] <project>` copies the `groma` and `groma-*` skill folders installed next to its own skill, so it copies what the user has. Skill folders per agent come from `agents.yaml`, the version from `VERSION`.
- Rules, as in `cli/skills.js`: a missing file is created; a recorded file whose hash still matches is replaced; a recorded file the user edited is kept and reported; an existing file or skill folder without a record is a conflict and stays untouched; records outside the selected agents' `groma*` folders are carried over.
- Deletion: a recorded, unchanged file is deleted only when groma no longer ships it, that is when the file left a skill that this run copies, or when its skill is listed in `skills/groma/retired-skills.txt` (maintained at the release that drops a skill). A skill that is merely absent from the source is never deleted: a bundle, a `--skills` selection or an older groma would otherwise remove a project's copies. `cli/skills.js` follows the same rule, because an older `npx groma-cli` meets a newer project the same way.
- No downgrade: when `generated.json` names a newer `generatedBy` than the running groma, both paths stop with exit 1 unless `--force` is given.
- The source must lie outside the project. Run from a project's own copies (a teammate without the plugin runs `/groma` from `.claude/skills/groma/`), the script stops with exit 1 and names the plugin, `npx skills add` and the CLI: copies carry the user's edits and files and must not become a source.
- Symbolic links: a link at or above a destination path below the skills folder is a conflict; the script never writes into it and never deletes from it. A skills folder that leads out of the project is a conflict for that agent. A skills folder linked to another folder inside the project (`.claude/skills -> ../.agents/skills`) is used as it is. The CLI follows links; this is the one place where the script is stricter.
- The plan is complete before the first write, and unreadable or uncopyable source names stop the run before it. When a write itself fails, `generated.json` still records the files written so far.
- Copied `SKILL.md` files get `metadata.generatedBy: groma@<version>`, byte for byte as `addGeneratedBy` writes it (a file with a BOM or CRLF frontmatter is copied unchanged, as in the CLI).
- `generated.json` has the CLI's layout with keys in byte order. The CLI sorted with `localeCompare`, which depends on the machine's locale data; it now sorts in byte order too, which equals `LC_ALL=C sort`.
- Hashes come from `sha256sum` or `shasum -a 256`.
- The script writes below `<skills_dir>/groma*/` and to `.groma/generated.json` only. It is the one runtime script that writes into the target project; the ownership rule of ADR 0018 keeps that within ADR 0006.

### Consequences

* Good, because `/groma` alone gives a complete, team-ready setup.
* Good, because the CLI and the agent path can refresh each other's copies: both read and write the same `generated.json`.
* Bad, because two implementations of one rule set can drift; the parity test is the guard.
* Bad, because the order of keys in `generated.json` changes once for projects whose file the older CLI wrote.

### Confirmation

`tests/scripts/materialize.bats` runs the scenarios of `cli/test/skills.test.js` against the script, plus smaller and older sources, the retired list, a run from the project's own copies, symbolic links and a comparison of `generatedBy` output with `addGeneratedBy` for odd frontmatter. Its parity test sets up one fixture with `groma init --yes` and one with `materialize.sh`, then applies the same edits and runs `groma update` and `materialize.sh --update`; after each step the copied files, their executable bits and `.groma/generated.json` must be byte-identical, with nothing normalized.

## Pros and Cons of the Options

### Let the agent copy the files itself

* Bad, because it is not deterministic, costs tokens for every file and cannot keep hashes reliably.

### Call the CLI's JavaScript from the skill

* Bad, because skills ship without `cli/`, and plugin users may have no package and no Node.

### Make the CLI call the shell script

* Good, because one implementation would remain.
* Bad, because the CLI's code is tested and fast and runs where `sh` may be missing (Windows without a POSIX shell). Open for a later change.

## More Information

Decision D1 of `openspec/changes/c016-agent-only-init/design.md`. Related: ADR 0005, ADR 0006, ADR 0015, ADR 0018, ADR 0051.
