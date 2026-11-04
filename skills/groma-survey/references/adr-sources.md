# Where ADRs hide

Search the whole repository (skip the `ignore` directories from groma-detect's signal table). A file counts as an ADR when its location matches a row below **and** its content looks like a decision record (a status, a decision section, or a title like "Use X").

| Kind | Pattern | Typical tool or convention |
|---|---|---|
| folder | `docs/adr/` | log4brains, groma |
| folder | `docs/decisions/` | MADR default |
| folder | `doc/adr/` | adr-tools default |
| folder | `doc/architecture/decisions/` | adr-tools, Nygard |
| folder | `docs/architecture/decisions/` | common variant |
| folder | `architecture/decisions/` | common variant |
| folder | `adr/`, `adrs/`, `decisions/` at any depth | free-form |
| folder | `docs/arc42/09*` or files named `*09_architecture_decisions*` | arc42 section 9 |
| folder | `.adr-dir` file content | adr-tools custom location |
| file | `**/ADR-*.md`, `**/adr-*.md`, `**/[0-9][0-9][0-9][0-9]-*.md` inside a docs folder | numbered records |
| file | `DECISIONS.md`, `decision-log.md`, `docs/decision-log.md` | single-file logs (one record per section) |
| file | `**/RFC-*.md`, `rfcs/` | RFCs that settled a decision; list them, mark as "RFC" |
| methodology | `openspec/changes/archive/*/design.md` "Decisions" sections | OpenSpec |
| methodology | `specs/*/research.md`, `specs/*/plan.md` decision notes | Spec Kit |

## Recording what you found

For each ADR: path, number (if any), title, status (as written, or `unknown`), date (frontmatter, "Date:" line, or first commit of the file).

Numbering for new ADRs continues after the highest number found in **any** location. Found ADRs stay where they are; the index in `docs/adr/README.md` links to them.
