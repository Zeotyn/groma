## MODIFIED Requirements

### Requirement: Mandatory docs tree
Every project initialized by groma SHALL have `docs/README.md`, `docs/vision.md`, `docs/concept.md`, `docs/architecture.md`, `docs/data-model.md`, `docs/glossary.md`, `docs/risks.md`, `docs/code-style.md` and `docs/adr/` with `docs/adr/README.md`.

#### Scenario: Greenfield
- **WHEN** groma runs in a greenfield project
- **THEN** all mandatory docs exist afterwards, filled from the interview where answers exist and marked "Not yet documented" elsewhere

#### Scenario: Update adds the code-style doc
- **WHEN** a project initialized with groma 0.2 runs groma 0.3 in update mode and no file fills the code-style slot
- **THEN** `docs/code-style.md` is created and added to the findings report as new, and no other doc changes
