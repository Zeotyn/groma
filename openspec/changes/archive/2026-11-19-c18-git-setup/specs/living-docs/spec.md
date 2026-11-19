## ADDED Requirements

### Requirement: Docs impact outside git
When the project is not a git repository with at least one commit, the docs impact script SHALL still report part (b), the design decisions without an ADR, SHALL print a `note` line that changed paths cannot be compared without git history, and SHALL NOT fail for that reason alone. With `--gate` it SHALL exit 4 only when part (b) reports something.

#### Scenario: Greenfield before the first commit
- **WHEN** the script runs with `--gate` on a change in a project without git and the change's design has no decision needing an ADR
- **THEN** it prints a `note` line naming the missing git history and `summary	impact=0	adr=0`, and exits 0

#### Scenario: Missing ADR without git
- **WHEN** the same project's change has a decision with an `Alternatives:` line and no ADR
- **THEN** the script reports the `adr` line and exits 4 with `--gate`
