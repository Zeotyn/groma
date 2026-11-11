# Doc slots

Every groma project has these slots. An existing file **fills** a slot when its path matches a pattern (case-insensitive) or its content clearly covers the slot's purpose. A filled slot gets no new file; the index links the existing one.

| Slot | groma file | Also fills the slot | Purpose |
|---|---|---|---|
| index | `docs/README.md` | `docs/index.md`, `docs/SUMMARY.md` | entry point listing all docs |
| vision | `docs/vision.md` | `VISION.md`, `docs/product.md`, `PRODUCT.md`, `docs/prd.md`, `docs/goals.md`, arc42 section 1 | why, goals, non-goals |
| concept | `docs/concept.md` | `docs/solution-strategy.md`, `docs/design.md`, `docs/overview.md`, arc42 sections 4 and 8 | solution strategy, key ideas |
| architecture | `docs/architecture.md` | `ARCHITECTURE.md`, `docs/ARCHITECTURE.md`, `docs/architecture/`, `docs/arc42/`, arc42 sections 3, 5-7 | context, containers, building blocks |
| data-model | `docs/data-model.md` | `docs/data_model.md`, `docs/datamodel.md`, `docs/schema.md`, `docs/erd.md`, `docs/database.md` | entities, relations, invariants |
| glossary | `docs/glossary.md` | `GLOSSARY.md`, `docs/terms.md`, `CONTEXT.md` (glossary sections), arc42 section 12 | domain terms |
| risks | `docs/risks.md` | `docs/technical-debt.md`, `docs/tech-debt.md`, `RISKS.md`, arc42 section 11 | risks, technical debt |
| code-style | `docs/code-style.md` | `CONTRIBUTING.md` or `.github/CONTRIBUTING.md` with a code-style section, `STYLEGUIDE.md`, `STYLE_GUIDE.md`, `docs/conventions.md`, `docs/style.md`, `docs/code-style.md`, `docs/coding-standards.md`, `docs/coding-guidelines.md` | tools table, conventions, style decisions |
| adr | `docs/adr/README.md` | any ADR location from groma-survey's `adr-sources.md` | decision index |

The code-style slot is special: when an existing file fills it, the missing parts (tools table, conventions) go into the findings report as a snippet, and `docs/code-style.md` is not created. The tools table is filled from [code-style-tools.md](code-style-tools.md): one row per tool found by `style-drift.sh` (brownfield) or chosen in the interview (greenfield).

Optional slots (only when listed in `docs.optional` of `.groma/config.yaml`): `constraints`, `quality`, `security`, `operations`, `stakeholders`, templates in `templates/docs/optional/`.

## Placeholders in templates

- `{{today}}`: current date, `YYYY-MM-DD`.
- `{{owner}}`: `git config user.name`, else `TBD`.
- `{{project_name}}`: from config, else the folder name.
- `{{sources}}`: comma-separated code and config paths the doc describes (from the survey), else leave the list empty. Never docs paths or change folders such as `openspec/changes/`.
- `{{name: hint}}`: replace with real content following the hint. Unknown content: write `Not yet documented.`; in tables, drop the placeholder row and add `| Not yet documented. | | |` only if the table would be empty.
- `{{status:<slot>}}`, `{{reviewed:<slot>}}` in the index: the slot doc's frontmatter `status` and `last_reviewed`, or `-` for docs without frontmatter.
