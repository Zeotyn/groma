# Project signals

Single source of truth for greenfield/brownfield detection. `scripts/detect.sh` parses the table below; agents read it to explain verdicts. Add a row to support a new stack, no code change needed.

Kinds:

- `source`: file extension that counts as source code, with the stack it hints at.
- `nonsource`: extension that never counts as source code (docs, config, assets). Any extension that is neither `source` nor `nonsource` still counts as source, labeled "unrecognized stack".
- `manifest`: file name that marks a build or dependency setup, matched at any depth.
- `ignore`: directory name that is skipped entirely.

| Kind | Pattern | Label |
|---|---|---|
| source | .js | JavaScript |
| source | .mjs | JavaScript |
| source | .cjs | JavaScript |
| source | .jsx | JavaScript (React) |
| source | .ts | TypeScript |
| source | .tsx | TypeScript (React) |
| source | .vue | Vue |
| source | .svelte | Svelte |
| source | .py | Python |
| source | .java | Java |
| source | .kt | Kotlin |
| source | .kts | Kotlin script |
| source | .scala | Scala |
| source | .groovy | Groovy |
| source | .go | Go |
| source | .rs | Rust |
| source | .c | C |
| source | .h | C/C++ header |
| source | .cpp | C++ |
| source | .cc | C++ |
| source | .hpp | C++ header |
| source | .cs | C# |
| source | .fs | F# |
| source | .vb | Visual Basic |
| source | .swift | Swift |
| source | .m | Objective-C |
| source | .dart | Dart |
| source | .rb | Ruby |
| source | .php | PHP |
| source | .ex | Elixir |
| source | .exs | Elixir script |
| source | .erl | Erlang |
| source | .clj | Clojure |
| source | .hs | Haskell |
| source | .ml | OCaml |
| source | .lua | Lua |
| source | .pl | Perl |
| source | .r | R |
| source | .jl | Julia |
| source | .zig | Zig |
| source | .nim | Nim |
| source | .sql | SQL |
| source | .sh | Shell |
| source | .ps1 | PowerShell |
| source | .tf | Terraform |
| source | .sol | Solidity |
| source | .abap | ABAP |
| source | .cob | COBOL |
| source | .prisma | Prisma schema |
| source | .graphql | GraphQL schema |
| source | .proto | Protocol Buffers |
| nonsource | .md | Markdown |
| nonsource | .mdx | MDX |
| nonsource | .txt | Text |
| nonsource | .rst | reStructuredText |
| nonsource | .adoc | AsciiDoc |
| nonsource | .json | JSON |
| nonsource | .jsonc | JSON |
| nonsource | .yaml | YAML |
| nonsource | .yml | YAML |
| nonsource | .toml | TOML |
| nonsource | .ini | INI |
| nonsource | .cfg | Config |
| nonsource | .conf | Config |
| nonsource | .env | Environment |
| nonsource | .xml | XML |
| nonsource | .csv | CSV |
| nonsource | .lock | Lockfile |
| nonsource | .log | Log |
| nonsource | .png | Image |
| nonsource | .jpg | Image |
| nonsource | .jpeg | Image |
| nonsource | .gif | Image |
| nonsource | .svg | Image |
| nonsource | .webp | Image |
| nonsource | .ico | Image |
| nonsource | .pdf | Document |
| nonsource | .docx | Document |
| nonsource | .pptx | Document |
| nonsource | .xlsx | Spreadsheet |
| nonsource | .drawio | Diagram |
| nonsource | .excalidraw | Diagram |
| nonsource | .keep | Placeholder |
| nonsource | .gitkeep | Placeholder |
| nonsource | .mdc | Agent rules |
| manifest | package.json | Node.js |
| manifest | deno.json | Deno |
| manifest | bun.lockb | Bun |
| manifest | pyproject.toml | Python |
| manifest | requirements.txt | Python |
| manifest | setup.py | Python |
| manifest | Pipfile | Python |
| manifest | pom.xml | Java (Maven) |
| manifest | build.gradle | JVM (Gradle) |
| manifest | build.gradle.kts | JVM (Gradle) |
| manifest | build.sbt | Scala (sbt) |
| manifest | go.mod | Go |
| manifest | Cargo.toml | Rust |
| manifest | Gemfile | Ruby |
| manifest | composer.json | PHP |
| manifest | mix.exs | Elixir |
| manifest | pubspec.yaml | Dart/Flutter |
| manifest | Package.swift | Swift |
| manifest | CMakeLists.txt | C/C++ (CMake) |
| manifest | Makefile | Make |
| manifest | Dockerfile | Container |
| manifest | docker-compose.yml | Container |
| manifest | compose.yaml | Container |
| manifest | gleam.toml | Gleam |
| manifest | stack.yaml | Haskell |
| manifest | dune-project | OCaml |
| manifest | build.zig | Zig |
| ignore | .git | git metadata |
| ignore | node_modules | dependencies |
| ignore | vendor | dependencies |
| ignore | .venv | dependencies |
| ignore | venv | dependencies |
| ignore | target | build output |
| ignore | dist | build output |
| ignore | build | build output |
| ignore | .groma | groma state |
| ignore | .claude | agent config |
| ignore | .cursor | agent config |
| ignore | .gemini | agent config |
| ignore | .codex | agent config |
| ignore | .agents | agent config |
| ignore | .specify | methodology |
| ignore | openspec | methodology |
| ignore | .bmad-core | methodology |
| ignore | _bmad | methodology |
| ignore | .planning | methodology |
| ignore | .idea | editor |
| ignore | .vscode | editor |

## Verdict rules

- **brownfield** when at least one of: a source file, a manifest, or more than 10 commits.
- **greenfield** otherwise. If Markdown docs exist, the signal `docs present` is added and the docs are input for the interview.
- The user can always override the verdict; the override is stored in `.groma/config.yaml` as `project_type_override`.
