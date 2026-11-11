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

### Requirement: Shared methodology recipes
Methodology init recipes SHALL live in one data file read by both the CLI and the `groma-methodology` skill. Each recipe SHALL declare: id, detection paths (already present), prerequisites, the init command with its agent-id mapping, the files it touches, whether it can run non-interactively, and the docs link step.

#### Scenario: New methodology version
- **WHEN** a contributor bumps the OpenSpec version in the recipe file
- **THEN** both `groma init` and the skill use the new version, with no other file changed

### Requirement: Methodology rules for living docs
When `docs.gate` is `review` or `strict` and groma created the methodology's config in this run, groma SHALL add rules requiring a `## Docs impact` section in every proposal (affected docs and planned ADRs, or "none, because …"), a final `Docs` task group in every tasks file, and an "Alternatives" paragraph for every design decision. When the config already existed, groma SHALL put the rules as a snippet into the findings report instead.

#### Scenario: Fresh OpenSpec setup
- **WHEN** groma runs `openspec init` in a project without `openspec/config.yaml`
- **THEN** the created config has the three rules under `rules.proposal`, `rules.tasks` and `rules.design`, each as a quoted string

#### Scenario: Existing OpenSpec config
- **WHEN** `openspec/config.yaml` existed before the run
- **THEN** the file is unchanged and the findings report contains the rules as a snippet

### Requirement: Code style in methodology context
When groma creates the methodology's config, its project context SHALL include "Code style lives in docs/code-style.md or the code-style doc listed in docs/README.md; follow it and run its check commands." When the config already existed, the line SHALL go into the findings report as a snippet.

#### Scenario: Fresh OpenSpec setup
- **WHEN** groma creates `openspec/config.yaml`
- **THEN** its `context` contains the code-style line next to the docs line

