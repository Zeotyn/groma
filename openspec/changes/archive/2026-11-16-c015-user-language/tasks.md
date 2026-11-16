## 1. Tests first

- [x] 1.1 Eval: empty fixture with German answers; assert German questions and summary, English groma artifacts

## 2. Rule

- [x] 2.1 "User language" rule in groma and every skill step that addresses the user
- [x] 2.2 `scripts/test.sh` green; eval run recorded here
  - `scripts/test.sh` green on 2026-11-16 (structure check `user-language` included). The `de-empty` eval run is deferred to the joint M004 eval run and ran on 2026-11-16 (report 2026-11-16T154408): `de-empty` PASS, all language checks ok, $1.68. Limit: the eval prompt is German too, so the eval shows German talk with English files but barely discriminates the rule itself (an agent may answer German anyway); no baseline run without the rule is planned.

## 3. Docs

- [x] 3.1 `docs/concept.md` crosscutting concept; ADR with the open docs-language question; CHANGELOG `[Unreleased]`
