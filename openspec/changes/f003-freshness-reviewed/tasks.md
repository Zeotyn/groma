## 1. Tests first

- [ ] 1.1 `tests/scripts/freshness.bats`: reviewed same day → fresh; source commit the next day → stale with `last_reviewed` in the reason; no `last_reviewed` → old behavior; existing cases unchanged

## 2. Implementation

- [ ] 2.1 `freshness.sh` rule (b) per D1, header comment updated
- [ ] 2.2 `shellcheck -s sh` and `scripts/test.sh` green

## 3. Docs

- [ ] 3.1 `docs/concept.md` freshness paragraph; proposed ADR for D1 with `origin: f003-freshness-reviewed#D1`; ADR index
- [ ] 3.2 CHANGELOG `[Unreleased]`: Fixed entry
- [ ] 3.3 Run `freshness.sh .` on this repository and record the result here; expected: architecture, concept, data-model and glossary fresh
