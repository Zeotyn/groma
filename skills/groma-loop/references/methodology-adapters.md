# Methodology adapters

How each loop phase maps to the project's methodology. Read only the section for `methodology` in `.groma/config.yaml`.

## openspec

| Phase | Author does | Artifacts the reviewer gets |
|---|---|---|
| propose | the OpenSpec propose workflow (`/opsx:propose`, or `openspec new change` plus the artifact instructions); name from `next-change-id.sh` | proposal.md, design.md, `specs/**/spec.md`, tasks.md |
| apply | the OpenSpec apply workflow for one review unit (`per`), ticking tasks as it goes | the unit's tasks, the requirements they cover, `git diff <base>`, test output |
| verify | the OpenSpec verify workflow, then the docs gate | its report, the full change diff and the docs impact report |
| archive | the OpenSpec archive workflow with spec sync, then the docs sync, then the git steps (archive commit `docs(openspec): archive <change-id>`, integration, push) | none (no review) |

Task group = a `## N.` heading in tasks.md. Commit scope `<scope>` for the propose and archive commits: `openspec`. `<proposal title>` (squash subject, `per: change` unit title): the slug of the change name with dashes as spaces (`c007-cache-layer` → "cache layer"); when proposal.md starts with a `# ` heading, that heading instead.

## spec-kit

| Phase | Author does |
|---|---|
| propose | `/speckit.specify`, `/speckit.plan`, `/speckit.tasks` in `specs/<id>-<slug>/` |
| apply | `/speckit.implement` for one review unit |
| verify | re-read spec.md acceptance criteria against the diff |
| archive | none; mark the feature done in `docs/roadmap.md` |

Task group = a phase heading in tasks.md. `<proposal title>`: the first heading of the feature's `spec.md`, else the humanized slug.

## generic (bmad, gsd, none)

| Phase | Author does |
|---|---|
| propose | write `proposal.md` and `tasks.md` in the change folder named by the convention |
| apply | work through the tasks of one review unit |
| verify | check every task and the proposal's goals against the diff |
| archive | move the change folder to the methodology's archive (or `<changes>/archive/YYYY-MM-DD-<name>/`) |

The docs gate, the docs sync and the git steps (SKILL.md, Verify and Archive) run the same way for every methodology; `<change-dir>` is the change folder before archiving. Commit scope `<scope>`: `spec-kit`, `bmad`, `gsd`, and `changes` for `none`. `<proposal title>` for the generic methodologies: the first heading of `proposal.md`, else the humanized slug. Commit messages always go through a file (`git commit -F`), never `-m`.

Review records always go to `<change folder>/reviews/`.
