
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |

`unit-test-coverage` is `passed`: `test/deploy-overview.test.ts` carries one test per conformance vector (001-012) in its "overview conformance vectors" block, covering `summarizeByPlatform`, `deploysForEndpoint`, `latestTerminalForEndpoint`, `failuresForEndpoint` and the `platformCanon`/`deployTargetKey` re-exports. `separation-of-concerns` passes: the file performs no I/O, reads no configuration, and does exactly one thing — deploy-platform summarization and endpoint correlation — with the shared canonicalization delegated to the `canon` package rather than reimplemented here. `explicit-error-handling` passes: the one real failure case, an endpoint with no usable platform/project, is surfaced as an explicit `null` key from `deployTargetKey` and handled by an explicit `if (!key) return [];` guard rather than silently proceeding with a bogus correlation or throwing. `fault-tolerance` passes: every function accepts an empty `deploys` array, an `EndpointLike` with any or all of its three fields omitted, and any `DeployStatus` value its type allows (including `"unknown"`, per the open question above) without throwing.

The four correlation and summary functions still have no runtime importer in this repository — see the corresponding Design Decision above — but their behavior is now pinned by tests.

