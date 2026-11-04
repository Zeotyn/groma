## Purpose

Makes a project's code style explicit: detected or set up once, documented in `docs/code-style.md`, and followed by every agent that changes the code.

## ADDED Requirements

### Requirement: Code-style doc structure
`docs/code-style.md` SHALL have the sections "Enforced by tools" (table: tool, config path, check command, fix command), "Conventions" (one rule per line, each tagged `EXTRACTED` or `INFERRED` with a source path) and "Decisions" (ADR links). It SHALL link tool config files and SHALL NOT restate the rules they contain. Its frontmatter `sources` SHALL list the tool config files and the sampled source folders.

#### Scenario: Node project with Prettier and ESLint
- **WHEN** the project has `.prettierrc` and `eslint.config.js` and a `lint` script in `package.json`
- **THEN** the tools table has a Prettier row with `.prettierrc` and an ESLint row with `eslint.config.js` and `npm run lint`, and `sources` contains both config files

### Requirement: Tool reference table
Style tools SHALL be described in a reference table with stack, tool, role (`format` or `lint`), config file patterns, check command, fix command, install command and whether it is the recommended default for its stack. Detection and generation SHALL read this table; adding a tool SHALL need no change to skill logic.

#### Scenario: New tool by table row
- **WHEN** a row for `biome` with config pattern `biome.json` is added
- **THEN** a project with `biome.json` lists Biome in its tools table without any other change

### Requirement: Convention inference
In brownfield projects groma SHALL infer conventions from a sample of source files per top-level source folder: file and symbol naming, test location and naming, import style, error handling. Every convention SHALL cite at least one file path, with a line where it shows a specific construct. Conventions read from configuration (for example test globs) SHALL be tagged `EXTRACTED`, the rest `INFERRED`. Areas without a clear pattern SHALL say "No consistent pattern found."

#### Scenario: Inferred test location
- **WHEN** most test files sit next to their source as `*.spec.ts`
- **THEN** Conventions contains "Tests next to code as `*.spec.ts`" tagged `INFERRED` with two example paths

### Requirement: Static style drift
The survey SHALL report drift between `.editorconfig` and the code for `indent_style`, `end_of_line`, `insert_final_newline` and `trim_trailing_whitespace`, with the count of offending files and up to five examples, without running any project tool. It SHALL report a tool whose config exists but whose check command appears in neither CI workflow files nor project scripts.

#### Scenario: Tabs against editorconfig
- **WHEN** `.editorconfig` sets `indent_style = space` for `*.py` and 12 Python files indent with tabs
- **THEN** the findings report lists "indent_style drift: 12 files" with up to five paths

#### Scenario: Unchecked tool
- **WHEN** `ruff.toml` exists and no CI workflow or script mentions `ruff`
- **THEN** the findings report suggests adding `ruff check .` to CI

### Requirement: Style setup after the interview
When no style tool is detected, groma SHALL recommend tools for the detected or chosen stack from the reference table. After the user confirms, groma SHALL create `.editorconfig` and each tool's config as new files, record one ADR per chosen tool with `status: accepted`, and route dependency installs through the install consent flow. A tool whose setup needs editing an existing file SHALL be set up only through a snippet in the findings report.

#### Scenario: Greenfield TypeScript
- **WHEN** the user confirms Prettier and ESLint for a new TypeScript project
- **THEN** `.editorconfig`, `.prettierrc.json` and `eslint.config.js` exist, ADRs "Use Prettier for formatting" and "Use ESLint for linting" are accepted, and `npm i -D prettier eslint` runs only after consent, otherwise it is in `.groma/install.sh`

#### Scenario: Tool needs an existing build file
- **WHEN** the user picks Spotless for an existing Gradle project
- **THEN** `build.gradle` is unchanged and the findings report contains the Spotless snippet

#### Scenario: User declines
- **WHEN** the user answers "no tools"
- **THEN** no config file is created and "Enforced by tools" reads "None. Decided in the interview on <date>."

### Requirement: Existing style guides fill the slot
An existing `CONTRIBUTING.md`, `STYLEGUIDE.md`, `docs/conventions.md`, `docs/code-style.md` or a file matching the slot patterns SHALL fill the code-style slot. groma SHALL then create no new code-style doc and SHALL put missing sections (tools table, conventions) as a snippet into the findings report.

#### Scenario: CONTRIBUTING with style section
- **WHEN** `CONTRIBUTING.md` has a "Code style" section
- **THEN** `docs/code-style.md` is not created, the docs index links `CONTRIBUTING.md` as the code-style doc, and the tools table appears as a snippet in the findings report
