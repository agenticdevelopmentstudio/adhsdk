
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes because `useTablesWithRows.ts` only decides which tables hold rows: URL construction is delegated to `listUrl`, the network call to `authedJson`, session identity to `readTokenSubject` and `onSessionChange`, and presentation to the `CrudDataBrowser` rail that consumes the result. `unit-test-coverage` is `partial`: the exported `resetTablesWithRows` and `TABLES_WITH_ROWS_TTL_MS` exist for tests, and `packages/web/packages/crud/src/__tests__/CrudDataBrowser.workspace.test.tsx` pins the sweep end to end (Empty grouping, 403 and 404 handling, failed probes, remount caching, principal isolation, abort on unmount), but no test file targets the hook directly, so the concurrency bound and the nonexistent-array response are not asserted.

