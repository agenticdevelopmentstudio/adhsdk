
| Category | Check | Status |
|---|---|---|
| Best Practices | Separation of Concerns ([adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76)) | Passed |
| Best Practices | Unit Test Coverage ([adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437)) | Partial |
| Best Practices | Explicit Error Handling ([adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a)) | Partial |
| Reliability | Graceful Degradation ([adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f)) | Passed |
| Reliability | State Recovery ([adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674)) | Passed |
| Reliability | Data Integrity ([adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d)) | Passed |
| Reliability | Health Observability ([adc.check.reliability.health-observability](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d4ece88d-eeff-5e3f-8823-d8c2929a35e0)) | Partial |
| Reliability | Idempotent Operations ([adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b)) | Passed |
| Performance | Main Thread Freedom ([adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d)) | Passed |
| Performance | Resource Efficiency ([adc.check.performance.resource-efficiency](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d5fe7b8e-1051-5581-b2c5-1adae8fdd5fc)) | Passed |

Notes: Separation of concerns holds across all twelve types — each owns exactly one LSP capability, filesystem concern, or AppKit bridge, and none reaches into another's private state. Unit test coverage is partial because `TextDocumentCoordinator.swift` has no corresponding test file anywhere in the repository, while the other eleven types each have real, cited coverage. Explicit error handling and health observability are both partial for the same underlying reason: the two open findings noted beside the Behavioral Requirements above, where a caught error is discarded with no logging call. Graceful degradation, state recovery, data integrity, and idempotent operations are all passed on direct evidence — every async write is generation- or stamp-guarded, every lifecycle method (`start`, `shutdown`, `stop`) is idempotent, and every unsupported server capability degrades to a documented, tested fallback rather than a crash. Main thread freedom is passed because every AppKit-touching entry point asserts its thread, and every blocking file read is explicitly hopped off the main actor. Resource efficiency is passed on the refcounted directory watchers, the signature-based skip-the-read check, and the per-fetch (not per-token) divergence-ledger batching.

