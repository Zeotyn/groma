## Purpose

Offers a curated, categorized catalog of third-party skills so users choose what to activate per project instead of re-installing the same favourites by hand.

## ADDED Requirements

### Requirement: Categorized catalog
The suite SHALL ship a catalog that groups skills into categories. Each category SHALL declare its options, whether it allows single or multiple selection, a recommended choice and an optional condition. Initial categories: `design`, `writing`, `pragmatism`, `workflow`, `diagrams`, `discovery`.

#### Scenario: Initial catalog content
- **WHEN** a user lists the catalog
- **THEN** it contains at least: design (impeccable, frontend-design, none), writing (anti-ai-slop-writing, i-have-adhd, none), pragmatism (ponytail, none), workflow (superpowers, mattpocock-skills, none), diagrams (archify, none), discovery (graphify, repomix, none)

### Requirement: Conditional categories
A category with a condition SHALL be offered only when the condition holds for the project.

#### Scenario: No UI, no design question
- **WHEN** the project has no UI
- **THEN** the `design` category is not offered and is recorded as `none` with reason "no UI"

### Requirement: Multi-select categories
Categories marked multi-select SHALL accept several options.

#### Scenario: Two writing skills
- **WHEN** the user selects anti-ai-slop-writing and i-have-adhd under `writing`
- **THEN** both are recorded and installed

### Requirement: Project-local installation for configured agents
Selected skills SHALL be installed in project scope for every agent listed in the config, using the native plugin mechanism where available and `npx skills` otherwise.

#### Scenario: Claude and Copilot
- **WHEN** agents are `[claude, copilot]` and ponytail is selected
- **THEN** ponytail is available in both agents for this project, and the install commands used are logged in the findings report

#### Scenario: Agent may not run installers
- **WHEN** command execution is not permitted for the agent
- **THEN** groma writes `.groma/install.sh` with the exact commands and tells the user to run it

### Requirement: Groma uses selected writing skills for its own output
When a writing skill such as anti-ai-slop-writing is installed, groma SHALL apply it when it generates docs.

#### Scenario: Anti-slop active
- **WHEN** anti-ai-slop-writing is selected
- **THEN** generated vision, concept and ADR texts are written under that skill's rules

### Requirement: Extensible catalog
Adding a catalog entry SHALL require only a catalog file change: id, source repo, category and optional Claude plugin id and post-install command.

#### Scenario: Community adds a skill
- **WHEN** a contributor adds an entry with a valid source repo
- **THEN** the entry appears in the interview without any skill instruction changes, and catalog validation passes in CI
