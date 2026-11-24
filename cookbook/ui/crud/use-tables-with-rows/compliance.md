
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because `useTablesWithRows.ts` only decides which tables hold rows: URL construction is delegated to `listUrl`, the network call to `authedJson`, session identity to `readTokenSubject` and `onSessionChange`, and presentation to the `CrudDataBrowser` rail that consumes the result. `unit-test-coverage` is `passed`: `packages/web/packages/crud/src/__tests__/useTablesWithRows.test.tsx` drives the hook directly and covers every conformance vector (001 through 011), including the concurrency bound of 8, the nonexistent-array response, probe order, caching, principal isolation and abort on unmount; `CrudDataBrowser.workspace.test.tsx` pins the same sweep through the rail.
