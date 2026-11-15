
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | Access Patterns |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |

`separation-of-concerns` passes: all 14 modules and `shared.ts` build a static
document; no module handles a real request, touches storage, or enforces auth —
those live one layer up in `src/routes/*`, `src/storage/*`, and `src/middleware/*`,
documented in the sibling recipes this one's `related` field points at.
`unit-test-coverage` is partial: `test/openapi.test.ts` exercises the ASSEMBLED
behavior with meaningful, specific assertions (the drift guard's two set
differences, the security-scheme shape, and the committed-`openapi.json`
snapshot), but no test targets `shared.ts`'s individual helpers directly —
`errors()` called with zero arguments, `zodJson`'s catch-fallback branch, and
`pathParam`/`queryParam`'s fixed shapes have no dedicated unit test of their own,
only indirect coverage through whichever operations happen to call them.
`explicit-error-handling` passes: the one place this component could swallow an
error, `zodJson`'s `try`/`catch`, converts the exception into an explicit,
documented fallback value instead of ignoring it or leaving it `undefined`.
`api-design-conventions` passes: `config.ts`'s `listCreate`/`patchDelete` helpers
give every resource collection the same GET-list/POST-create/PATCH-update/DELETE-
remove shape, `queryParam`/`pathParam`/`errors` keep parameter and error
documentation uniform across all 14 modules, and every path key is resource-
oriented and grouped by `tags`. `error-response-handling` is partial: every
failure code in this component resolves to one distinguishable, documented status
built through the shared `errors()` helper, with the acknowledged exceptions of
`/live/check`'s `503` and `DELETE /tokens/{id}`'s bare `204` diverging from the
`200`-plus-`okFlag` convention used elsewhere — real, traceable divergences
recorded in Design Decisions, not a uniform contract. `data-minimization` passes:
`PeerRow` and the `POST /tokens` response are the two places a secret could leak
into this documented surface, and both are constructed to minimize it — `PeerRow`
substitutes `hasToken: boolean` for the raw `peerInsert.token`, and only the
one-time `201` create response for a minted token includes the raw value at all.

