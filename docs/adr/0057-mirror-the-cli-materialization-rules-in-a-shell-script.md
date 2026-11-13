---
status: accepted
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
- No downgrade: when `generated.json` names a newer `generatedBy` than the running groma, both paths stop with exit 1 unless `--allow-downgrade` is given; `--force` only replaces edited files. A pre-release counts as older than its release.
- The source must be groma itself, not a copy groma made. The script decides by what the source is, not by where it lies: a source whose `SKILL.md` carries `generatedBy` (only copies do) is refused with exit 1, whatever its path or spelling, because copies carry the user's edits and files. A project-level `npx skills add` install is a valid source; an agent skills folder that is the source folder itself is skipped with a note, and its links in other agents' folders are conflicts, so nothing is copied onto itself. groma's own repository as the project is refused.
- Symbolic links, on both paths: a link at or above a destination path below the skills folder is a conflict, never written into and never deleted from. A skills folder that leads out of the project is a conflict for that agent. A skills folder linked to another folder inside the project (`.claude/skills -> ../.agents/skills`) is used as it is.
- Crash safety, on both paths: `generated.json` is written before the first file is touched, with planned creates at their new hash and updates and removals at their old one, under the old `generatedBy`; each file is written beside its place and renamed; the final `generated.json` follows. A run that fails or is killed leaves every file it wrote recorded. The script also stops before the first write on source names it cannot copy.
- Copied `SKILL.md` files get `metadata.generatedBy: groma@<version>`, byte for byte the same on both paths: an existing line is replaced, never doubled; a file with a BOM or CRLF frontmatter is copied unchanged.
- `generated.json` has the CLI's layout with keys in byte order. The CLI sorted with `localeCompare`, which depends on the machine's locale data; it now sorts in byte order too, which equals `LC_ALL=C sort`.
- Hashes come from `sha256sum` or `shasum -a 256`.
- The script writes below `<skills_dir>/groma*/` and to `.groma/generated.json` only. It is the one runtime script that writes into the target project; the ownership rule of ADR 0018 keeps that within ADR 0006.

### Consequences

* Good, because `/groma` alone gives a complete, team-ready setup.
* Good, because the CLI and the agent path can refresh each other's copies: both read and write the same `generated.json`.
* Bad, because two implementations of one rule set can drift; the parity test is the guard.
* Bad, because the order of keys in `generated.json` changes once for projects whose file the older CLI wrote.

### Confirmation

`tests/scripts/materialize.bats` runs the scenarios of `cli/test/skills.test.js` against the script, plus smaller and older sources, `--force` without `--allow-downgrade`, the retired list, a run from copies groma made, a project-level install as source, symbolic links, a kill during the copy and a comparison of `generatedBy` output with `addGeneratedBy` for odd frontmatter. Its parity test sets up one fixture with `groma init --yes` and one with `materialize.sh`, then applies the same edits and runs `groma update` and `materialize.sh --update`; after each step the copied files, their executable bits and `.groma/generated.json` must be byte-identical, with nothing normalized. A second parity test does the same with a skills folder linked to another one inside the project.

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
