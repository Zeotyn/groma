## ADDED Requirements

### Requirement: Methodology rules for living docs
When `docs.gate` is `review` or `strict` and groma created the methodology's config in this run, groma SHALL add rules requiring a `## Docs impact` section in every proposal (affected docs and planned ADRs, or "none, because …"), a final `Docs` task group in every tasks file, and an "Alternatives" paragraph for every design decision. When the config already existed, groma SHALL put the rules as a snippet into the findings report instead.

#### Scenario: Fresh OpenSpec setup
- **WHEN** groma runs `openspec init` in a project without `openspec/config.yaml`
- **THEN** the created config has the three rules under `rules.proposal`, `rules.tasks` and `rules.design`, each as a quoted string

#### Scenario: Existing OpenSpec config
- **WHEN** `openspec/config.yaml` existed before the run
- **THEN** the file is unchanged and the findings report contains the rules as a snippet
