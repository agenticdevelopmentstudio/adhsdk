
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | passed | Reliability |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |

`separation-of-concerns` passes: each of the 13 store files owns exactly one
port's implementation against the driver, `owned-deploys.ts` owns exactly
one shared predicate, and none of the 14 files contains a route handler,
an HTTP concern, or a monitor-cycle scheduling decision — those live in
sibling modules that import this layer rather than being imported by it.
`unit-test-coverage` passes: the sibling `test/` suite exercises the
last-admin guard (`last-admin-guard.int.test.ts`), the upsert ordering and
minimum/COALESCE rules (`upsert-deployments.test.ts`,
`deploy-upsert-guard.test.ts`), the errors-reconciliation sweep
(`telemetry-errors-store.int.test.ts`), the device-authorization flow
(`device-flow.int.test.ts`), and the group/site/endpoint delete cascade
(`site-delete-purge.int.test.ts`) — each targeting exactly the atomic-guard
or reconciliation behavior that would be easiest to silently regress.
`explicit-error-handling` passes: every tolerated failure path in this
layer (the not-yet-migrated-table checks, the fail-soft checkpoint and
snapshot, the orphan-reconcile catch) matches a specific, narrow error
signature or is logged before being swallowed — none of the 14 files
contains a bare catch that discards an error with no signal at all.
`data-integrity` passes: every atomic guard in this recipe (last-admin,
device-grant single-use, TOCTOU-safe conditional deletes, webhook-vs-poll
ordering) is expressed as a single SQL statement rather than a
read-then-write pair, so the invariant it protects cannot be violated by
an interleaving of two concurrent calls. `idempotent-operations` passes:
`upsertDeployments`, `errorsStore.save`, `recordVercelProdStates`, and
every peer-snapshot/project-meta upsert are all safe to call repeatedly
with the same or updated input, converging on the latest state rather
than accumulating duplicates. `state-recovery` passes: `peer-store.ts`'s
snapshot table and `observation-store.ts`'s platform-health state exist
specifically so a restarted process recovers the fleet's last-known state
from disk rather than starting blank, mirroring the same pattern the
`status-server-libsql` recipe documents for the schema those tables
belong to. `secure-storage` passes: `auth-store.ts`, `token-store.ts`, and
`device-store.ts` persist a hash, never a raw secret, with exactly one
documented, time-boxed, single-use exception (`tokenRaw` in
`device-store.ts`, cleared atomically by `consumeApproved`).
`no-pii-in-logs` passes: every logged message identified in this recipe's
Logging section names a deployment id, a step name, a file path, or a
row count — never an email, a password hash, a session/API/device-code
hash, or a `tokenRaw` value.

