## Purpose

Keeps `docs/` current as the project changes: every change updates the docs its code affects and records its design decisions as ADRs, checked by a deterministic report.

## ADDED Requirements

### Requirement: Docs impact report
groma SHALL provide a read-only script that, for a change folder, lists (a) every doc whose frontmatter `sources` contain a path changed since the change's base while the doc itself is unchanged, with the changed paths, and (b) every design decision that needs an ADR and has none. The base SHALL default to the parent of the commit that added the change's proposal, or the working tree against `HEAD` when that commit does not exist. ADRs and docs without `sources` SHALL NOT be checked under (a). The script SHALL exit 0 with a report, and exit 4 when `--gate` is given and the report is not empty.

#### Scenario: Code changed, doc not
- **WHEN** a change modifies `skills/groma-loop/SKILL.md` and `docs/architecture.md` has `sources: [skills/]` and is unchanged
- **THEN** the report has a line `impact	docs/architecture.md	skills/groma-loop/SKILL.md`

#### Scenario: Doc updated in the change
- **WHEN** the same change also modifies `docs/architecture.md`
- **THEN** the report has no line for it

#### Scenario: Gate on a clean change
- **WHEN** `--gate` is given and nothing is reported
- **THEN** the script prints `summary	impact=0	adr=0` and exits 0

### Requirement: Explicit no-impact
A task line `Docs: <path> unchanged, because <reason>` in the change's tasks file SHALL clear `<path>` from the report. A line without a reason SHALL NOT clear it.

#### Scenario: Justified exemption
- **WHEN** tasks.md contains `- [x] Docs: docs/data-model.md unchanged, because no entity changed`
- **THEN** `docs/data-model.md` is not reported

### Requirement: ADR candidates from design decisions
With `docs.adr_from: design-alternatives` (default), every decision heading in the change's design that has an "Alternatives" paragraph SHALL need an ADR. With `marked`, only decisions containing a line `ADR: yes` SHALL. With `off`, none SHALL. An ADR covers a decision when its frontmatter has `origin: <change>#<decision id>`. groma SHALL write such ADRs with `status: proposed` during the change, in MADR 4.0, numbered after the highest existing ADR.

#### Scenario: Decision with alternatives
- **WHEN** `design.md` of `c007-cache` has `### D2: Use Redis` with an "Alternatives:" paragraph and no ADR has `origin: c007-cache#D2`
- **THEN** the report has a line `adr	c007-cache#D2	Use Redis`

#### Scenario: Decision covered
- **WHEN** `docs/adr/0011-use-redis.md` has `origin: c007-cache#D2`
- **THEN** the report has no `adr` line for D2

### Requirement: Docs sync on archive
When a change is archived through groma, groma SHALL set every ADR with this change's `origin` and `status: proposed` to `accepted`, set `last_reviewed` to today in every doc the change modified, add missing ADRs to `docs/adr/README.md`, and regenerate the roadmap. groma SHALL edit only docs that the change itself created or modified.

#### Scenario: Archive accepts ADRs
- **WHEN** `c007-cache` is archived and `docs/adr/0011-use-redis.md` has `origin: c007-cache#D2` and `status: proposed`
- **THEN** the ADR reads `status: accepted` and the ADR index lists it as accepted

### Requirement: Gate levels
`docs.gate` SHALL control enforcement: `off` disables report use; `remind` shows the report only through status reminders; `review` (default) additionally adds the methodology rules and makes every report line a high finding in groma-loop's verify; `strict` additionally refuses archive while the report is not empty.

#### Scenario: Strict blocks archive
- **WHEN** `docs.gate: strict` and the report lists `docs/concept.md`
- **THEN** groma-loop does not archive and escalates with the report
