
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |

**Separation of Concerns**: Fetching and board staleness sit in `useBoard`, the live transport in `useLiveSnapshot`, the snapshot staleness rule in `lib/snapshot-staleness.ts`, and the server-to-glyph mapping in `lib/overview.ts`; the hook only composes them, and text formatting stays with callers.

**Unit Test Coverage**: `use-portfolio-indicator.dom.test.tsx` covers a present board backing its verdict and a null board rendering unknown; `use-board.dom.test.tsx` covers the hook agreeing with `GlobalPanel` on a stale board. The offline, blind and stale-snapshot branches, the `"warn"` and `"down"` mappings and the `count` value are not asserted by the hook's own tests, though `snapshotFreshness` has its own test file.

**Graceful Degradation**: Any missing, failed, blind or stale input degrades the sign to `"unknown"` instead of a false green.

**Data Integrity**: The colour is the server's `board.indicator` mapped one-to-one; the hook never recomputes severity and never shows a retained verdict.

