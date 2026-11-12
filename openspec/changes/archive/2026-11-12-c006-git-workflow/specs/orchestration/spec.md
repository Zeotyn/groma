## ADDED Requirements

### Requirement: Integration strategy question
In a git repository the interview SHALL ask for the integration strategy and push policy. In greenfield projects the recommended option SHALL be `rebase` with `push: ask`. In brownfield projects the recommended option SHALL be the history-based recommendation, shown with its evidence.

#### Scenario: Brownfield with pull-request merges
- **WHEN** the history script reports 28 "Merge pull request" commits out of 30 merges
- **THEN** the interview recommends `merge` and shows "28 of 30 merges are pull-request merges"
