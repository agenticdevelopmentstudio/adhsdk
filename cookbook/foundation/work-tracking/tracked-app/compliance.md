
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

The type separates the data model and lookup from recording, persistence and display, which live in the recorder, the preferences and the settings panel. `AppAllowlistTests` (`Tests/AgenticDeveloperHubSDKCoreTests/WorkTracking/AppAllowlistTests.swift`) covers every vector, including sort order, removed-beats-added, an added id that is already a default, and duplicate injected defaults, so coverage passes. The allowlist limits recording to a named set of apps and holds no user content.

