
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

`separation-of-concerns` passes because the file only models, decodes and fetches the health body; it holds no polling schedule, rendering or alerting, which belong to the menu bar app. `unit-test-coverage` is partial: the `DaemonHealthReportTests` suite in `AgenticDeveloperHubSDKMenuBarTests/MenuSectionTests.swift` covers decoding a full wire body and a body in another schema, and the menu section tests build the types, but `DaemonHealthProbe.http`, the unknown-state failure, the missing-key failures and `first(ofKind:)` ordering have no direct test. `timeout-configuration` passes because the probe takes a `timeout` parameter with a 2 second default and applies it to the request. `graceful-degradation` passes because every probe failure and every decode mismatch returns `nil` rather than throwing, so a client keeps running when the daemon is down or answers in another shape.

