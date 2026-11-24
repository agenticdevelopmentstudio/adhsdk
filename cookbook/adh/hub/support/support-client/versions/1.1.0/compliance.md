
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

The module is written, in `wire.ts`, `grants.ts` and `index.ts`. Both checks stay partial. Separation of concerns: the wire types and mappers are apart in `wire.ts`, but `grants.ts` holds the four clients, the rules the panes read and every hook in one file. Unit-test coverage: `__tests__/support.test.ts` covers every client's paths and bodies, `grantState`, `groupAccess`, `isSupportOff`, `isStepUpRequired`, `SUPPORT_CONTENT_TABLES` and `supportRequestProblem`; no hook is tested, so the hook requirements (**hook-names**, **hooks-keys**, **writes-invalidate**) are unasserted.
