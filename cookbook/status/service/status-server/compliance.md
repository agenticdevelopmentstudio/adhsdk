
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | partial | reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | passed | reliability |
| [adc.check.reliability.health-observability](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d4ece88d-eeff-5e3f-8823-d8c2929a35e0) | passed | reliability |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | performance |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | access-patterns |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | access-patterns |

Separation of concerns: The server is composed of modular route handlers (authRoutes, usersRoutes, reads, etc.) that are injected into `createApp`, separating business logic (each route module) from infrastructure (middleware, CORS, error handling, auth seam). Storage is an abstract interface (port), decoupling data access from the HTTP layer. The scheduler is a separate concern, injected as optional dependency and used only by specific routes (stream, health).

Unit test coverage: `test/scheduler.test.ts` covers single-flight, grid re-anchoring, the manual flag, coalescing, watchdog self-heal and staleness; `test/health.int.test.ts`, `test/status-summary.int.test.ts` and `test/body-limit.int.test.ts` cover the public routes, the summary rollup, caching, the stampede guard, CORS and the 413 cap. `isAllowedOrigin` and `isPublicPath` are module-private and exercised only through the app.

Timeout handling: The scheduler implements a hard timeout (cycleTimeoutMs) on each cycle via a watchdog timer. If a cycle exceeds the timeout, the watchdog releases the single-flight lock and logs an error, preventing the process from wedging. It does not cancel the abandoned cycle, and a late resolution still advances `lastCycleAt`, hence partial. Long-running network operations (fetch within the cycle callback) are subject to the cycle timeout, not managed independently by the server.

Error recovery: The scheduler catches all cycle errors (try/catch inside tick) and logs them; errors do not crash the process or stop future ticks. Failed cycles do not advance `lastCycleAt` (an abandoned cycle that later resolves does, contrary to its doc comment), so `/health` can detect that the last-completed timestamp is stale. The watchdog timer prevents a single hung await from breaking the loop.

Health observability: The server exposes `/health` with status and `lastCycleAt` timestamp, providing visibility into whether the monitoring loop is running and keeping up. Stale detection via `cycleStale()` signals when the loop is wedged. Errors are logged to console (see Logging section).

Caching strategy: The `/public/status-summary` endpoint uses a 30-second cache with single-flight pattern. Cache invalidation is time-based (TTL); the next `buildStatusSummary` call happens automatically after 30 seconds. `createApp` never passes `fresh`, so there is no explicit invalidation; a failed build is not cached.

API design conventions: The server follows REST conventions: GET for reads (`/health`, `/version`, `/public/status-summary`), POST/PATCH/DELETE for mutations, standard HTTP status codes (200 for success, 503 for service unavailable, 413 for payload too large, 500 for server error). The OpenAPI spec is served at `GET /doc`, behind the auth seam.

Error response handling: All HTTP errors are returned in the format `{error: {message: "..."}}` with appropriate status codes. Non-HTTP exceptions are logged and returned as 500 with message `Internal Server Error`; a failed auth resolution is 401 `Unauthorized`. The caller is responsible for parsing error responses and deciding whether to retry (e.g., 503 from `/health` indicates staleness, not a client error).

