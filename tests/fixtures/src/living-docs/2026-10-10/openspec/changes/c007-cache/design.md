## Decisions

### D1: Cache in front of reads
Every read goes through `src/cache.js`.

### D2: Use Redis
Redis holds the cache entries.

Alternatives: an in-process map (rejected: lost on restart).

## Risks / Trade-offs

- Alternatives considered elsewhere do not count outside a decision.
