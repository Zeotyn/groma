# Methodology adapters

How each loop phase maps to the project's methodology. Read only the section for `methodology` in `.groma/config.yaml`.

## openspec

| Phase | Author does | Artifacts the reviewer gets |
|---|---|---|
| propose | the OpenSpec propose workflow (`/opsx:propose`, or `openspec new change` plus the artifact instructions); name from `next-change-id.sh` | proposal.md, design.md, `specs/**/spec.md`, tasks.md |
| apply | the OpenSpec apply workflow for one review unit (`per`), ticking tasks as it goes | the unit's tasks, the requirements they cover, `git diff <base>`, test output |
| verify | the OpenSpec verify workflow, then the docs gate | its report, the full change diff and the docs impact report |
| archive | the OpenSpec archive workflow with spec sync, then the docs sync | none (no review) |

Task group = a `## N.` heading in tasks.md.

## spec-kit

| Phase | Author does |
|---|---|
| propose | `/speckit.specify`, `/speckit.plan`, `/speckit.tasks` in `specs/<id>-<slug>/` |
| apply | `/speckit.implement` for one review unit |
| verify | re-read spec.md acceptance criteria against the diff |
| archive | none; mark the feature done in `docs/roadmap.md` |

Task group = a phase heading in tasks.md.

## generic (bmad, gsd, none)

| Phase | Author does |
|---|---|
| propose | write `proposal.md` and `tasks.md` in the change folder named by the convention |
| apply | work through the tasks of one review unit |
| verify | check every task and the proposal's goals against the diff |
| archive | move the change folder to the methodology's archive (or `<changes>/archive/YYYY-MM-DD-<name>/`) |

The docs gate and docs sync (SKILL.md, Verify and Archive) run the same way for every methodology; `<change-dir>` is the change folder before archiving.

Review records always go to `<change folder>/reviews/`.
