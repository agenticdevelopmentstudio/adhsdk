
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3.1 | 2026-11-23 | Mike Fullerton | billing-routes-since: GET /billing/entries reads a timestamp `since` as the earliest calendar day that instant falls on in any zone (UTC-12), not its text prefix, and its 400 names both accepted forms (review f8). |
| 1.3.0 | 2026-11-21 | Mike Fullerton | Account credential store, quota probe, account router and its routes (credential relay) moved into Database/Daemon. Billing routes (every stenographerd billing call) and activity routes with a work tracker's controls added for adhd. |
| 1.2.2 | 2026-11-19 | Mike Fullerton | Name the CLI sentinel without the host's name |
| 1.2.1 | 2026-11-18 | Mike Fullerton | Per-feature summary provider resolution (`summaryAIProviderSettings(for:)`). |
| 1.2.0 | 2026-10-04 | Mike Fullerton | Restate rollback-failure and cross-instance-reentrancy as current behavior with pending decisions. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to data/storage/. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation from `BoundedDatabase.swift`, `AppStorageLocation.swift` and their tests |
