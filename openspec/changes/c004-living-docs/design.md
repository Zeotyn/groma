## Context

`docs/` is created by groma-lay-out and checked by groma-survey's `freshness.sh` (fixed in F001). Changes run through OpenSpec, alone or inside groma-loop. Nothing connects a change to the docs it affects. The data needed for that already exists: frontmatter `sources` map docs to code, `git diff` lists what a change touched, and `design.md` holds decisions with alternatives. Evidence from this repository: after C002, `architecture.md`, `concept.md` and `glossary.md` do not mention `groma-loop`, and none of C002's D1–D6 has an ADR.

## Goals / Non-Goals

**Goals:**
- A deterministic check, cheap enough to run in every verify and status call.
- Docs and ADRs are written by the author inside the change, like code.
- One escape hatch with a stated reason. No empty edits just to pass.
- Works without groma-loop, as reminders. The gate is enforced only inside the loop.

**Non-Goals:**
- Judging whether a doc's content is correct. The reviewer does that.
- Hooks into OpenSpec's own `archive` command.
- Editing existing methodology configs. This change only adds rules when groma creates the config.

## Decisions

### D1: Impact = changed paths ∩ doc `sources`
`docs-impact.sh [--base <ref>] [--gate] <change-dir>` takes the project root as `--root` (default `.`), diffs `<base>..` plus the working tree, and prefix-matches each changed path against each non-ADR doc's `sources`. The default base is the parent of the commit that added `<change-dir>/proposal.md`. If that commit does not exist, the base is `HEAD`, so only working-tree changes count. It reuses F001's frontmatter parsing, which is copied into the script because skills are self-contained. Output: `impact<TAB>doc<TAB>paths`, `adr<TAB>change#Dn<TAB>title`, `summary<TAB>impact=n<TAB>adr=n`.

Alternatives: ask the reviewer model to judge docs impact (rejected: not repeatable and costs a round); map impact by doc slot (architecture ← any code) (rejected: too coarse, would flag every doc on every change).

### D2: ADR link through `origin` frontmatter
An ADR written from a design decision carries `origin: <change>#<Dn>`. Decision ids come from headings `### D<n>:` in `design.md`. An "Alternatives" paragraph is a line starting with `Alternatives` inside the decision section. The `marked` mode looks for a line `ADR: yes` instead.

Alternatives: match ADR titles to decision titles (rejected: titles get edited); ask in every proposal which decisions need ADRs (rejected: forgotten as soon as nobody asks).

### D3: Four gate levels, default `review`
`off`, `remind`, `review` and `strict` build on each other (see the living-docs spec). `review` fits the autonomous loop: the author must answer docs findings like any high finding, and a human is pulled in only on disagreement. `strict` is for teams that want archive to block.

Alternatives: a boolean on/off (rejected: solo projects want reminders without blocking, teams want blocking); block by default (rejected: too strict for the first run on a brownfield project whose docs are years old).

### D4: Docs edits inside a change are authored work, not setup writes
ADR 0006 forbids groma's setup skills from editing existing files. Updating `docs/architecture.md` inside a user's change is the same kind of work as editing code in that change, which the user asked for. The archive sync edits only docs that the change created or modified, so it never touches a doc the change did not already touch.

Alternatives: write doc updates as snippets into `docs/_groma/` (rejected: docs would never become current); extend ADR 0006 with exceptions (rejected: blurs a simple rule; a new ADR states the scope instead).

### D5: Escape hatch is a task line
`Docs: <path> unchanged, because <reason>` lives in the tasks file, so it is reviewed with the change and archived with it. A reason is required, and the line must match the pattern `because .+`.

Alternatives: a frontmatter flag on the doc (rejected: it changes the doc only to silence the check); a separate ignore file (rejected: it outlives the change and hides future impact).

## Risks / Trade-offs

- [Docs without `sources`, which is common in brownfield projects, are invisible to the report] → groma-survey already reports missing frontmatter. The findings snippet suggests a `sources` list.
- [Broad sources like `skills/` flag the doc on every change] → intended for architecture-level docs. The escape hatch keeps it cheap, and narrower sources are the fix.
- [Base detection fails for squashed or rebased history] → `--base` overrides. Fallback to working tree is announced in the output.
- [Agents skip the Docs task group outside the loop] → status reminder plus the AGENTS.md line. Enforcement exists only in the loop, by design.

## Migration Plan

- Validator accepts the new keys. Missing keys mean `review` / `design-alternatives`.
- `upgrades.md` row for 0.2.0: offer to add the `docs` keys, and print the OpenSpec rules snippet for existing configs.
- First run on this repository: add ADRs for C002 D1–D6 (`accepted`, `origin: c002-review-loop#Dn`), proposed ADRs for C003 D1–D7, and ADRs for this change's D1–D5. Update architecture, concept and glossary for groma-loop.

## Open Questions

- Should the docs impact also run at the propose phase, reading the planned `## Docs impact` section instead of a diff? Deferred until the apply-time check has been used on real changes.
