# suite-testing Specification

## Purpose
Defines how the groma suite itself is tested, so contributions stay safe: structure checks, script tests, the never-overwrite invariant, and agent evals on fixture repositories, enforced in CI.
## Requirements
### Requirement: Structure validation
CI SHALL validate on every pull request: SKILL.md frontmatter (`name` equals folder, description within limits), plugin manifests, catalog schema, version consistency and internal Markdown links.

#### Scenario: Broken frontmatter
- **WHEN** a PR changes a SKILL.md `name` so it no longer matches its folder
- **THEN** CI fails with the file and the mismatch

### Requirement: Script tests
Every shell script in the suite SHALL have automated tests that run on Linux and macOS in CI.

#### Scenario: Freshness script
- **WHEN** the freshness script runs on a fixture whose doc is older than its sources
- **THEN** the test asserts that the doc is reported as stale

### Requirement: Fixture repositories
The suite SHALL maintain fixtures covering at least: empty folder, Node with Prisma, Java with Flyway, Python/Django with stale docs, Go without a database. Fixture git history SHALL be generated deterministically.

#### Scenario: Deterministic history
- **WHEN** fixtures are generated twice
- **THEN** commit dates and file contents are identical

### Requirement: Never-overwrite invariant
Tests SHALL verify on every brownfield fixture that all pre-existing files are byte-identical after a groma run.

#### Scenario: Violation detected
- **WHEN** a change causes a run to alter `README.md` in a fixture
- **THEN** the invariant test fails and names the changed file

### Requirement: Agent evals
Evals SHALL run groma headless against each fixture and SHALL assert the expected outcomes: classification, mandatory docs present, ADRs present or proposed, stale docs reported, data-model tags present. Evals SHALL run only on demand (a manual workflow run, or a pull request labeled `eval`) and in a milestone's release gate, never on a schedule and not on every PR, because every run costs API tokens.

#### Scenario: Greenfield eval
- **WHEN** the eval runs on the empty fixture with scripted interview answers
- **THEN** it asserts all mandatory docs and seed ADRs exist and `.groma/config.yaml` is valid

#### Scenario: No scheduled runs
- **WHEN** a day passes without anyone starting the evals workflow or labeling a pull request `eval`
- **THEN** no eval run starts and no API tokens are spent

### Requirement: Token report
Each eval run SHALL write, per fixture, the input, output and cache tokens, the cost in USD, the number of turns and the duration to a report file, and SHALL print the totals. When a committed baseline exists, the run SHALL print the difference per fixture against it.

#### Scenario: Report after a run
- **WHEN** `scripts/test.sh evals` finishes
- **THEN** the run's own report `tests/evals/reports/<date>T<time>.tsv` has one row per fixture with tokens and cost, and the output ends with the totals

#### Scenario: Comparison with the baseline
- **WHEN** `tests/evals/reports/baseline.tsv` exists and a run finishes
- **THEN** each fixture's line shows its token and cost difference against the baseline

