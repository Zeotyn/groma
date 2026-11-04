## Purpose

Gives every groma project the same naming and numbering convention for changes from day one, so humans and agents can tell milestones, changes and fixes apart at a glance and trace work back to milestones.

## ADDED Requirements

### Requirement: Change name format
Every change created in a groma project SHALL be named `<type><NNN>-<slug>`: `type` is a lowercase type letter, `NNN` a three-digit, zero-padded number, and `slug` kebab-case. Docs and summaries SHALL display the id in uppercase (e.g. `C004`).

#### Scenario: New change
- **WHEN** the user asks for a new feature "export as CSV" and the highest existing change number is `c003`
- **THEN** the change is named `c004-export-csv`

#### Scenario: Uppercase input
- **WHEN** a user or agent requests the name `C4-Export`
- **THEN** groma normalizes it to `c004-export` and says so

### Requirement: Default types
groma SHALL define these default types: `m` milestone, `c` change, `f` fix, `s` spike, `r` refactor, `d` docs. `m`, `r` and `d` changes SHALL be created without spec deltas (in OpenSpec `skip_specs: true`). `s` changes SHALL NOT contain production code tasks.

#### Scenario: Refactor without spec delta
- **WHEN** a change of type `r` is created in OpenSpec
- **THEN** its `.openspec.yaml` contains `skip_specs: true`

#### Scenario: Spike outcome
- **WHEN** a spike `s001-evaluate-graphql` is completed
- **THEN** its result is captured as an ADR (accepted or rejected) or a follow-up change, not as code

### Requirement: Per-type numbering including archive
Numbers SHALL count independently per type. The next number SHALL be one above the highest number of that type found among active and archived changes, ignoring archive date prefixes. Numbers SHALL never be reused.

#### Scenario: Archived changes counted
- **WHEN** `openspec/changes/archive/2026-10-01-f002-null-on-empty/` exists and no active fix
- **THEN** the next fix is `f003-…`

#### Scenario: Collision on parallel branches
- **WHEN** two branches both create `c005-…` and are merged
- **THEN** the optional convention check reports the duplicate id, and groma suggests renaming the later one to the next free number

### Requirement: Milestones bundle changes
A milestone change SHALL state its goal, scope and the list of its child changes. Every child change SHALL reference its milestone in its proposal with a `Milestone: mNNN` line. Changes without a milestone SHALL be allowed.

#### Scenario: Child change references milestone
- **WHEN** `c001-user-login` is created while milestone `m001-mvp` is active and the user assigns it
- **THEN** the proposal of `c001-user-login` contains `Milestone: m001`, and `m001-mvp` lists `c001-user-login`

### Requirement: Roadmap tracking
groma SHALL create `docs/roadmap.md` when the first milestone is created and SHALL list each milestone with goal, child changes and their status (active or archived).

#### Scenario: Progress shown
- **WHEN** milestone `m001` has three children, two of them archived
- **THEN** `docs/roadmap.md` shows `M001` with "2/3 done" and the remaining child

### Requirement: Configurable convention
The convention SHALL be stored in `.groma/config.yaml` under `conventions.changes` (types, digits, separator). Users SHALL be able to add types or disable the convention. Brownfield projects with existing change names SHALL keep them; the convention applies to new changes only.

#### Scenario: Custom type
- **WHEN** the user adds type `p` = "performance" to the config
- **THEN** new performance changes are named `p001-…`, and numbering of other types is unaffected

#### Scenario: Existing unprefixed changes
- **WHEN** a brownfield project has `openspec/changes/add-dark-mode/`
- **THEN** groma does not rename it, and new changes follow the convention

### Requirement: Enforcement in the methodology and for agents
groma SHALL make the convention known to agents by writing it into AGENTS.md (when created by groma) and into the methodology's rule mechanism where one exists (for OpenSpec: `rules` in `openspec/config.yaml`, only when groma initializes OpenSpec). For methodologies with their own numbering, groma SHALL document the mapping (e.g. BMAD epic ↔ milestone).

#### Scenario: Agent creates a change
- **WHEN** an agent in a groma project with OpenSpec runs a propose workflow
- **THEN** the convention text is part of the context it receives, and the change name follows `<type><NNN>-<slug>`

### Requirement: Convention check
groma SHALL provide a check that lists changes violating the convention and duplicate ids, usable locally and in CI of the target project.

#### Scenario: Violation reported
- **WHEN** a new change `fix-login` is added after groma initialization
- **THEN** the check reports `fix-login` with the suggested name `f00N-login`
