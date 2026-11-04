## MODIFIED Requirements

### Requirement: Freshness frontmatter
Every doc created by groma SHALL start with YAML frontmatter containing `title`, `status`, `last_reviewed`, `review_after_days`, `owner` and `sources`. `sources` SHALL name code and configuration paths that outlive a change; it SHALL NOT name other docs or paths inside change folders such as `openspec/changes/`.

#### Scenario: Architecture doc frontmatter
- **WHEN** groma creates `docs/architecture.md` in a project with `src/`
- **THEN** its frontmatter has `status: draft`, today's date as `last_reviewed`, `review_after_days: 90` and `sources` listing the code paths described

#### Scenario: Decision taken in a change
- **WHEN** a doc explains a decision recorded in `openspec/changes/c005-x/design.md`
- **THEN** its `sources` list the code paths that implement the decision, and the doc links the ADR, not the change folder
