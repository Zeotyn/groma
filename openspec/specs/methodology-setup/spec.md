# methodology-setup Specification

## Purpose
Initializes the chosen spec-driven methodology non-interactively and wires it to the project's `docs/`, so the user does not have to set up each framework by hand.
## Requirements
### Requirement: Supported methodologies
groma SHALL offer `openspec` (recommended), `spec-kit`, `bmad`, `gsd` and `none`, and SHALL initialize the chosen one for the configured agents without interactive prompts.

#### Scenario: OpenSpec for Claude and Copilot
- **WHEN** methodology is `openspec` and agents are `[claude, copilot]`
- **THEN** OpenSpec is initialized for both tools, and its project context points to `docs/README.md`

#### Scenario: Methodology already present
- **WHEN** `openspec/` already exists
- **THEN** groma does not re-initialize it, records `methodology: openspec` and reports "already initialized"

### Requirement: Optional workflow layer
groma SHALL allow an optional workflow layer (e.g. superpowers) that is installed in addition to the methodology.

#### Scenario: OpenSpec plus superpowers
- **WHEN** the user selects `openspec` and workflow `superpowers`
- **THEN** both are installed, and AGENTS.md states that OpenSpec owns specs and changes while superpowers owns the working style (planning, TDD)

### Requirement: docs/ stays the product truth
The methodology setup SHALL link the methodology to `docs/` instead of duplicating vision, architecture or data model content.

#### Scenario: Spec Kit constitution
- **WHEN** methodology is `spec-kit`
- **THEN** the generated constitution references `docs/vision.md` and `docs/concept.md` instead of copying their content

### Requirement: Missing prerequisites
When a required runtime (e.g. Node ≥ 22 or `uv`) is missing, groma SHALL stop this step, name the missing tool and the install command, and continue with the remaining steps.

#### Scenario: uv missing for Spec Kit
- **WHEN** methodology is `spec-kit` and `uv` is not installed
- **THEN** groma reports "uv missing: install via https://docs.astral.sh/uv/" and marks the step as pending in the config

