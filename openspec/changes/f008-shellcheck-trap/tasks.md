## 1. Fix

- [x] 1.1 Disable SC2317 next to SC2329 on the trap-only `unlock` function in `next-stop.sh`
- [x] 1.2 shellcheck 0.10.0 (CI) and 0.11.0 (local) clean over all scripts `scripts/test.sh` checks; `scripts/test.sh` green
- [x] Docs: `docs/code-style.md` unchanged, because the shellcheck rule it documents stays the same
- [x] Docs: `docs/architecture.md` unchanged, because only a lint directive in `next-stop.sh` changes, not its behaviour
- [x] Docs: `docs/concept.md` unchanged, because only a lint directive in `next-stop.sh` changes, not its behaviour
- [x] Docs: `docs/glossary.md` unchanged, because no term changes
