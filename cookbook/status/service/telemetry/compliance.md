
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |

**Separation of Concerns**: The `collect()` abstraction decouples fetching (provider API calls) from persistence (storage strategies). Each of `Fetcher`, `Store`, and `collectTelemetry`'s orchestration concerns is isolated behind an interface. Concrete adapters (GlitchTip fetcher, SQLite store, PostHog fetcher) are wired only at the composition root (`server.ts`), allowing tests and deployments to swap implementations without changing the core logic.

**Unit Test Coverage**: `test/telemetry-collect.test.ts` in the status-server package covers all ten conformance vectors (`telemetry-001` to `telemetry-010`): `collect`'s ok:false no-persist rule and `complete` defaulting, `collectTelemetry`'s concurrency, configuration guards, fail-soft handling and the GlitchTip observation, and `emptySnapshot`. The provider fetchers are mocked at the module boundary, so no test touches the network.
