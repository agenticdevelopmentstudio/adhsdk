
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

`separation-of-concerns` passes because the file only models, decodes and fetches the health body; it holds no polling schedule, rendering or alerting, which belong to the menu bar app. `unit-test-coverage` is partial: 25 of 27 vectors have a test. `DaemonHealthReportConformanceTests.swift` (Core tests) covers every vector except 001 and 002, which the `DaemonHealthReportTests` suite in `AgenticDeveloperHubSDKMenuBarTests/MenuSectionTests.swift` covers. It runs the probe against a loopback HTTP responder. Skipped: daemon-health-report-015 (the 2 second idle timeout needs a real wait) and daemon-health-report-021 (a body trickled for several real seconds). `timeout-configuration` passes because the probe takes a `timeout` parameter with a 2 second default and applies it to the request. `graceful-degradation` passes because every probe failure and every decode mismatch returns `nil` rather than throwing, so a client keeps running when the daemon is down or answers in another shape.

