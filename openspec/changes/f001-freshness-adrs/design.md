## Context

`skills/groma-survey/scripts/freshness.sh` decides per doc: `last_reviewed + review_after_days` overdue, or newest commit under `sources` newer than the doc's commit, or (no `sources`) any non-Markdown commit outside the docs folder newer than the doc. Run on this repository it gives `stale=15 fresh=2`: all eight ADRs fall into the third rule, `docs/README.md` has `sources: [docs/]`, and `concept.md` and `risks.md` list `openspec/changes/c001-groma-suite/design.md`, which moved to the archive. `git log -- <moved path>` still returns the move commit, so the doc looks stale instead of broken.

## Goals / Non-Goals

**Goals:**
- Only real findings: a stale line means "a human should reread this doc".
- Broken `sources` are visible as their own kind.
- Existing consumers of the output keep working.

**Non-Goals:**
- A docs-impact gate for changes (C004).
- Detecting stale content semantically.
- Changing `last_reviewed` handling or day granularity.

## Decisions

### D1: ADRs are snapshots, checked only for open decisions
An ADR records a decision at a date; later code changes make a new ADR necessary, not the old one stale. Files under `<docs>/adr/` skip both code rules. `status: proposed` older than `--adr-days` (default 30) is stale. Age comes from frontmatter `date`, else the last commit.

Alternatives: check ADRs against their `evidence` paths (rejected: an accepted ADR does not change when evidence changes; that is a superseding decision, which C004 detects from change designs); exempt ADRs completely (rejected: undecided proposals would rot silently).

### D2: Doc-to-doc sources are ignored
Sources inside the docs folder are dropped before the code rule. If nothing remains, the doc gets only the review-date rule. This keeps the index (`docs/README.md`) quiet whenever another doc changes.

Alternatives: forbid docs paths in `sources` only (rejected: existing projects already have them and would stay noisy).

### D3: New kind `broken`, summary field appended
A source that does not exist, or lies under a change folder, makes the doc `broken`. One line per doc, priority `broken` > `stale` > `fresh`; the reason lists every broken path and, if the doc is also stale, the stale reason after `; `. The summary becomes `summary stale= fresh= unknown= broken=`; appending keeps every existing prefix match valid.

Change-folder prefixes live in one variable at the top of the script (`openspec/changes/`). Other methodologies keep their change folders inside paths that stay (Spec Kit `specs/NNN-*`), so one prefix covers today's catalog.

Alternatives: report broken sources as stale reasons (rejected: the fix is different, edit frontmatter, not reread the doc); a separate script (rejected: one more call for the survey and C004).

## Risks / Trade-offs

- [A project keeps ADRs outside `docs/adr/`] → they are still treated as ordinary docs; groma-survey's `adr-sources.md` locations can be added later as an option.
- [Hard-coded change-folder prefix is methodology knowledge in a script] → single variable, documented in the script header; moves into a reference table if a second methodology needs it.
- [Consumers that parse the summary with an exact match] → only our bats tests do that; they are updated.

## Migration Plan

No migration. Projects see fewer stale lines and possibly new `broken` lines on the next survey.
