
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

`unit-test-coverage` passes: `test/refresh-project-meta.int.test.ts` exercises
both `syncVercelProjectMeta` (five cases: full eviction, chunked upsert/prune,
partial-read no-eviction, unconfigured no-eviction, last-project-deleted
eviction) and `refreshVercelProjectMeta` (fetch-then-evict, and no-token
fail-closed) directly against a real storage instance, covering every branch
this recipe documents. `separation-of-concerns` passes: this file owns exactly
one concern — reconciling `deploy_project_meta`'s Vercel rows against a
snapshot — and delegates fetching to `fetchVercelProductionStates` and token
resolution to `providerConn`, reimplementing neither. `explicit-error-handling`
passes on its narrow "MUST NOT silently swallow" bar: none of the three
functions contains a `try`/`catch`, so every storage or fetch rejection
propagates intact to the caller rather than being caught and discarded.
`idempotent-operations` passes: calling `syncVercelProjectMeta` repeatedly with
the same snapshot converges to, and stays at, the same stored row set — the
upsert's `onConflictDoUpdate` and the eviction's set-diff are both naturally
idempotent per the source's own chunking implementation in `deploy-store.ts`.
`data-integrity` is rated partial, not failed, because within a single,
non-overlapping call the three-step reconcile is internally consistent (the
integration tests confirm the intended upsert/evict outcome every time); the
open question on concurrent-invocation-not-guarded is what keeps it from a full
pass — nothing in this file wraps the upsert, the read-back, and the delete in
one transaction or lock, so two overlapping invocations (this codebase's actual
callers include a periodic monitor cycle and a request-path cache, coordinated
with each other in neither file) could interleave and produce an incorrect
prune list or a lost upsert. `graceful-degradation` passes: a partial
(`ok: false`) or unconfigured read degrades to "upsert what came back (if any),
evict nothing" rather than either crashing or wiping the table on incomplete
information, which is exactly the behavior `no-eviction-attempt-when-not-ok-or-not-configured`
and the partial-read test vector pin.

