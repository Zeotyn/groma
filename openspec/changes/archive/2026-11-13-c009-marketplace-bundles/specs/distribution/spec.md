## ADDED Requirements

### Requirement: Marketplace bundles
The Claude Code marketplace SHALL offer, besides the full plugin `groma`, the bundles `groma-docs` (groma-detect, groma-survey, groma-lay-out) and `groma-loop` (groma-loop). Each bundle SHALL install only its skills, SHALL work without the CLI and without the other groma skills, and SHALL carry the same version as the full plugin.

#### Scenario: Docs bundle only
- **WHEN** a user runs `claude plugin install groma-docs@groma`
- **THEN** groma-detect, groma-survey and groma-lay-out are available, no other groma skill is installed, and a survey of a brownfield project produces its findings report

#### Scenario: Bundle versions
- **WHEN** a release tag `v0.4.0` is checked
- **THEN** every bundle manifest declares `0.4.0`, and the release check fails if one differs
