## 1. Tests first

- [x] 1.1 Structure check for description length and AGENTS.md template lines (fails on today's text where it exceeds)

## 2. Diet

- [x] 2.1 Trim the eight descriptions
- [x] 2.2 Trim the AGENTS.md template
- [x] 2.3 Eval run; character proxy recorded here; `scripts/test.sh` green
  Proxy: descriptions 2384 → 1821 characters (−24 %), 1817 after review; AGENTS.md template 54 → 53 lines, 488 → 444 words, 3246 → 2966 characters (−9 %), 3013 after review restored "Keep this file short".
  Evals 2026-11-12: 8 passed, 0 failed (all fixtures).
  The token difference against the C010 baseline moved to `openspec/changes/c010-token-report/tasks.md` task 2.4.
- [x] 2.4 Caps bind after review: total of 2000 characters for all descriptions, 3200 characters for the AGENTS.md template (design D1); boundary tests; eval assertion that a generated AGENTS.md has at most 80 lines (written, not run)

## 3. Docs

- [x] 3.1 CHANGELOG `[Unreleased]`; concept or ADR per D1
- [x] Docs: docs/architecture.md unchanged, because the structure check's role and the skills' layout stay the same.
- [x] Docs: docs/glossary.md unchanged, because no term changes.
- [x] Docs: docs/vision.md unchanged, because only the README's line count changes.
- [x] Docs: docs/roadmap.md unchanged, because C010 only gains a task and its status stays the same.
