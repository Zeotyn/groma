## MODIFIED Requirements

### Requirement: Change name format
Every change created in a groma project SHALL be named `<type><N>-<slug>`: `type` is a lowercase type letter, `N` a number without leading zeros, and `slug` kebab-case. Inside a milestone the name SHALL be `m<N>-[<type word>-]<slug>`, where N is the milestone number and the optional type word is `spike`, `fix` or `refactor`. Docs and summaries SHALL display ids in uppercase (e.g. `C4`, `M3`).

#### Scenario: New change
- **WHEN** the user asks for a new feature "export as CSV" and the highest existing change number is `c3`
- **THEN** the change is named `c4-export-csv`

#### Scenario: Uppercase input
- **WHEN** a user or agent requests the name `C004-Export`
- **THEN** groma normalizes it to `c4-export` and says so

#### Scenario: Fix inside a milestone
- **WHEN** a fix belongs to milestone 3
- **THEN** it is named `m3-fix-<slug>`, and tools treat it as a fix

### Requirement: Default types
groma SHALL define these default types: `m` milestone member, `c` change, `f` fix, `s` spike, `r` refactor. `s` changes, `m<N>-spike-` changes and `r` changes SHALL be created without spec deltas (in OpenSpec `skip_specs: true`). Spikes SHALL NOT contain production code tasks and SHALL end with an ADR (`status: proposed`) or a follow-up change.

#### Scenario: Refactor without spec delta
- **WHEN** a change of type `r` is created in OpenSpec
- **THEN** its `.openspec.yaml` contains `skip_specs: true`

#### Scenario: Spike outcome
- **WHEN** a spike `s1-evaluate-graphql` is completed
- **THEN** its result is captured as an ADR with `status: proposed` or a follow-up change, not as code

#### Scenario: No docs type
- **WHEN** an agent asks for the next id of type `d` with the default types
- **THEN** groma reports `d` as unknown and says docs belong to the change that causes them

### Requirement: Per-type numbering including archive
Numbers for `c`, `f`, `s` and `r` SHALL count independently per type. The next number SHALL be one above the highest number of that type found among active and archived changes, ignoring archive date prefixes and leading zeros of old names. Numbers SHALL never be reused. For `m`, the next number SHALL be one above the highest milestone number found in `docs/roadmap.md` headings and in `m<N>-` names, active and archived.

#### Scenario: Archived changes counted
- **WHEN** `openspec/changes/archive/2026-10-01-f2-null-on-empty/` exists and no active fix
- **THEN** the next fix is `f3-…`

#### Scenario: Old padded names counted
- **WHEN** the archive holds `c016-agent-only-init` and no higher change
- **THEN** the next change is `c17-…`

#### Scenario: Collision on parallel branches
- **WHEN** two branches both create `c5-…` and are merged
- **THEN** the convention check reports the duplicate id, and groma suggests renaming the later one to the next free number

### Requirement: Milestones bundle changes
A milestone SHALL NOT be a change. It SHALL be a section `## M<N>: <title>` in `docs/roadmap.md` with a `**Goal:**` line and a `**Release gate:**` checklist. A change SHALL belong to milestone N exactly when its name starts with `m<N>-`. Changes without a milestone SHALL be allowed.

#### Scenario: Child change references milestone
- **WHEN** `m3-checkout` and `m3-payment` exist and `docs/roadmap.md` has `## M3: Checkout`
- **THEN** both are listed under M3 without any line in their proposals

### Requirement: Roadmap tracking
groma SHALL create `docs/roadmap.md` with a section template when the first milestone is planned. The roadmap script SHALL replace only the text between `<!-- groma:changes m<N> -->` and `<!-- /groma:changes -->` in each section with that milestone's changes (name, active or archived, tasks done) and SHALL leave all other text unchanged. For changes listed in the conventions baseline it SHALL also accept a `Milestone: mNNN` line.

#### Scenario: Progress shown
- **WHEN** milestone 1 has three changes, two of them archived
- **THEN** the M1 block in `docs/roadmap.md` lists all three with their state and the hand-written goal stays as written

#### Scenario: Section without markers
- **WHEN** a section `## M2: Billing` has no marker block
- **THEN** the roadmap script leaves it unchanged and the convention check reports the missing block with a snippet

### Requirement: Configurable convention
The convention SHALL be stored in `.groma/config.yaml` under `conventions.changes` (types, separator). A `digits` key SHALL be ignored with a validator warning. Users SHALL be able to add types or disable the convention. Brownfield projects with existing change names SHALL keep them; the convention applies to new changes only.

#### Scenario: Custom type
- **WHEN** the user adds type `p` = "performance" to the config
- **THEN** new performance changes are named `p1-…`, and numbering of other types is unaffected

#### Scenario: Existing unprefixed changes
- **WHEN** a brownfield project has `openspec/changes/add-dark-mode/`
- **THEN** groma does not rename it, and new changes follow the convention

#### Scenario: Old digits setting
- **WHEN** the config has `conventions.changes.digits: 3`
- **THEN** the validator warns that `digits` is ignored, and ids have no padding

### Requirement: Enforcement in the methodology and for agents
groma SHALL make the convention known to agents by writing it into AGENTS.md (when created by groma) and into the methodology's rule mechanism where one exists (for OpenSpec: `rules` in `openspec/config.yaml`, only when groma initializes OpenSpec). For methodologies with their own numbering, groma SHALL document the mapping (e.g. BMAD epic ↔ milestone section).

#### Scenario: Agent creates a change
- **WHEN** an agent in a groma project with OpenSpec runs a propose workflow
- **THEN** the convention text is part of the context it receives, and the change name follows `<type><N>-<slug>`

### Requirement: Convention check
groma SHALL provide a read-only check that lists changes violating the convention, duplicate ids (`<type><N>` for `c`, `f`, `s`, `r`; the full name for `m`) and milestone sections without a marker block, usable locally and in CI of the target project. With `--suggest-migration` it SHALL print a new name for each old-format name and, for each umbrella milestone change, a roadmap section built from its proposal.

#### Scenario: Violation reported
- **WHEN** a new change `fix-login` is added after groma initialization
- **THEN** the check reports `fix-login` with the suggested name `f<N>-login`

#### Scenario: Old names in the baseline
- **WHEN** `c016-agent-only-init` is listed in `.groma/conventions-baseline.txt`
- **THEN** the check accepts it

#### Scenario: Migration suggestions
- **WHEN** the check runs with `--suggest-migration` on a project with `m004-v0-4` and a child whose proposal says `Milestone: m004`
- **THEN** it prints the child's new name `m4-<slug>` and a `## M4:` section with the goal, the open release-gate tasks and an empty marker block, and changes no file
