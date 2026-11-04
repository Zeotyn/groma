# project-detection Specification

## Purpose
Classifies a target folder as greenfield or brownfield from observable signals, so later steps know whether to interview the user or survey existing code.
## Requirements
### Requirement: Classification
Detection SHALL classify the folder as `greenfield` or `brownfield` and SHALL list the signals that led to the result.

#### Scenario: Empty folder
- **WHEN** the folder contains no files other than `.git/`, `.groma/` or agent configuration folders
- **THEN** the result is `greenfield` with signal "no source files"

#### Scenario: Existing code base
- **WHEN** the folder contains source files in any language, a dependency manifest, or more than 10 commits of git history
- **THEN** the result is `brownfield` with the matching signals listed

#### Scenario: Only docs, no code
- **WHEN** the folder contains only Markdown docs and no source files
- **THEN** the result is `greenfield` with signal "docs present", and existing docs are treated as input for the interview

### Requirement: Stack-agnostic signals
Detection SHALL use a signal table that covers any language through file extensions and manifests, and SHALL NOT fail on unknown stacks.

#### Scenario: Unknown language
- **WHEN** the folder contains only `.gleam` files and no known manifest
- **THEN** the result is `brownfield` with signal "source files: .gleam (unrecognized stack)"

### Requirement: User override
The user SHALL be able to override the classification.

#### Scenario: Prototype code treated as greenfield
- **WHEN** detection reports `brownfield` and the user answers "treat as greenfield"
- **THEN** later steps run the greenfield interview, and the override is recorded in `.groma/config.yaml`

