# Code-style tools

One table for detection, the tools section of `docs/code-style.md` and greenfield setup. groma-survey's `style-drift.sh` reads it through `../groma-lay-out/references/`; groma-lay-out writes the templates it names. Add a tool by adding a row: no skill or script changes.

Columns:

- **Stack**: the languages the tool serves, matched against the languages and manifests groma-detect reports (`all` fits every project).
- **Role**: `format`, `lint`, or both as `format, lint`.
- **Config patterns**: shell globs at the project root that mean "configured", comma-separated. `file#text` means the file exists and contains `text` (a manifest section such as `pyproject.toml#[tool.ruff]`).
- **Check** and **Fix**: the commands as AGENTS.md lists them and as groma-loop runs them in the tests gate. Empty check: the tool is not run from a shell.
- **Install**: the dependency install that goes through the install consent flow. Empty: nothing to install, or the setup needs a snippet (see Notes).
- **Template**: path under `templates/code-style/`; the target is its file name at the project root. Empty: groma creates no file for this tool.
- **Default**: `yes` for the tool the interview recommends for its stack and role. Exactly one default per stack and role.

| Stack | Tool | Role | Config patterns | Check | Fix | Install | Template | Default |
|---|---|---|---|---|---|---|---|---|
| all | EditorConfig | format | `.editorconfig` | | | | `editorconfig/.editorconfig` | yes |
| JavaScript, TypeScript | Prettier | format | `.prettierrc`, `.prettierrc.*`, `prettier.config.*` | `npx prettier --check .` | `npx prettier --write .` | `npm i -D prettier` | `prettier/.prettierrc.json` | yes |
| JavaScript, TypeScript | ESLint | lint | `eslint.config.*`, `.eslintrc`, `.eslintrc.*` | `npx eslint .` | `npx eslint --fix .` | `npm i -D eslint @eslint/js` | `eslint/eslint.config.js` | yes |
| JavaScript, TypeScript | Biome | format, lint | `biome.json`, `biome.jsonc` | `npx biome check .` | `npx biome check --write .` | `npm i -D @biomejs/biome` | | no |
| Python | Ruff | format, lint | `ruff.toml`, `.ruff.toml`, `pyproject.toml#[tool.ruff]` | `ruff check . && ruff format --check .` | `ruff check --fix . && ruff format .` | `uv add --dev ruff` | `ruff/ruff.toml` | yes |
| Go | gofmt | format | `go.mod` | `test -z "$(gofmt -l .)"` | `gofmt -w .` | | | yes |
| Go | golangci-lint | lint | `.golangci.yml`, `.golangci.yaml`, `.golangci.toml` | `golangci-lint run` | `golangci-lint run --fix` | `go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.1.6` | | yes |
| Rust | rustfmt | format | `rustfmt.toml`, `.rustfmt.toml`, `Cargo.toml` | `cargo fmt --check` | `cargo fmt` | `rustup component add rustfmt` | `rustfmt/rustfmt.toml` | yes |
| Rust | clippy | lint | `clippy.toml`, `.clippy.toml`, `Cargo.toml` | `cargo clippy -- -D warnings` | `cargo clippy --fix` | `rustup component add clippy` | | yes |
| Java, Kotlin | Spotless | format | `build.gradle#spotless`, `build.gradle.kts#spotless`, `pom.xml#spotless-maven-plugin` | `./gradlew spotlessCheck` | `./gradlew spotlessApply` | | | yes |
| Ruby | RuboCop | format, lint | `.rubocop.yml` | `bundle exec rubocop` | `bundle exec rubocop -a` | `bundle add rubocop --group development` | `rubocop/.rubocop.yml` | yes |
| Shell | shellcheck | lint | `.shellcheckrc` | `shellcheck $(git ls-files '*.sh')` | | `brew install shellcheck` | `shellcheck/.shellcheckrc` | yes |
| Shell | shfmt | format | `.editorconfig#shell_variant` | `shfmt -d .` | `shfmt -w .` | `go install mvdan.cc/sh/v3/cmd/shfmt@v3.11.0` | `shfmt/.editorconfig` | yes |

Versions verified on 2026-11-11; bump them in a PR.

## Where checks run

`style-drift.sh` reports a configured tool as `unchecked` when neither its name nor the first two words of its check command appear in any of these places. `file`: the whole file. `package-scripts`: only the `scripts` object of the file.

| Kind | Pattern |
|---|---|
| file | `.github/workflows/*.yml` |
| file | `.github/workflows/*.yaml` |
| file | `.gitlab-ci.yml` |
| file | `.pre-commit-config.yaml` |
| file | `Makefile` |
| file | `justfile` |
| file | `Taskfile.yml` |
| file | `lefthook.yml` |
| package-scripts | `package.json` |

## Notes

- Templates are the tools' recommended base configs. Rule choices belong to the project and its ADRs, not to groma.
- Several chosen templates may share a target file name (`.editorconfig` from EditorConfig and shfmt): groma concatenates them, in table order, into that one new file.
- Spotless lives inside the build file. Its setup is a snippet in the findings report: plugin `com.diffplug.spotless` 7.0.2 with a `spotless { java { googleJavaFormat() } }` block for Gradle, or the `spotless-maven-plugin` for Maven. `build.gradle` and `pom.xml` stay untouched.
- gofmt, rustfmt and clippy ship with their toolchains; `go.mod` or `Cargo.toml` means they are available. golangci-lint, Biome and clippy run without a config file; their setup is the install command.
- A Prettier config inside `package.json` is not detected: a `prettier` key there is not distinguishable from the devDependency by a text match.
- `eslint.config.js` uses `import`; in a CommonJS project rename it to `eslint.config.mjs`.
- shellcheck installs also with `apt-get install shellcheck` or from the GitHub releases page.
