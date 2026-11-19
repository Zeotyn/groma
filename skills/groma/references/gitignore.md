# Ignore rules for a new repository

`scripts/git-init.sh` writes `.gitignore` from this table when groma set up the repository and the project has no `.gitignore`. An existing `.gitignore` is never changed. Add a stack by adding a row: no skill or script changes.

Columns:

- **Stack**: the languages or runtimes the row serves, matched case-insensitively against the stacks the interview named (`all` fits every project).
- **Manifests**: files at the project root that select the row even when the interview named no stack, comma-separated. Empty: only the stack name selects it.
- **Patterns**: the `.gitignore` lines, comma-separated, written in table order without duplicates.

| Stack | Manifests | Patterns |
|---|---|---|
| all | | `.DS_Store`, `Thumbs.db`, `*.swp`, `*~` |
| JavaScript, TypeScript, Node | `package.json` | `node_modules/`, `coverage/` |
| Python | `pyproject.toml`, `requirements.txt`, `setup.py` | `__pycache__/`, `*.pyc`, `.venv/`, `.pytest_cache/` |
| Rust | `Cargo.toml` | `target/` |
| Java, Kotlin | `pom.xml`, `build.gradle`, `build.gradle.kts` | `target/`, `build/`, `.gradle/` |
| Ruby | `Gemfile` | `.bundle/`, `vendor/bundle/` |
