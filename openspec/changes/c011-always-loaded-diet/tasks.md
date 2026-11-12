## 1. Tests first

- [x] 1.1 Structure check for description length and AGENTS.md template lines (fails on today's text where it exceeds)

## 2. Diet

- [x] 2.1 Trim the eight descriptions
- [x] 2.2 Trim the AGENTS.md template
- [ ] 2.3 Eval run; report difference against the C010 baseline recorded here; `scripts/test.sh` green
  Proxy until the C010 baseline exists: descriptions 2384 → 1821 characters (−24 %); AGENTS.md template 54 → 53 lines, 488 → 444 words, 3246 → 2966 characters (−9 %).

## 3. Docs

- [ ] 3.1 CHANGELOG `[Unreleased]`; concept or ADR per D1
- [x] Docs: docs/architecture.md unchanged, because the structure check's role and the skills' layout stay the same.
- [x] Docs: docs/glossary.md unchanged, because no term changes.
- [x] Docs: docs/vision.md unchanged, because only the README's line count changes.
