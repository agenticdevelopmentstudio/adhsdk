
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |

`separation-of-concerns` passes because the five files hold only data shapes and in-memory collection edits, while fingerprinting and scoring live in `SystemWindowMatcher`, cross-context rules in `SystemWindowContextManager` and file persistence in `SystemWindowContextStore`. `unit-test-coverage` is partial: 31 of 32 vectors have tests in `SystemWindowModelConformanceTests.swift` (under `Tests/AgenticDeveloperHubSDKCoreTests/SystemWindows/`), plus the matcher and manager tests already there. Vector wmcsw-032 (no file, network, log or process activity) is skipped because a unit test cannot observe the absence of side effects, and wmcsw-007 asserts only the score of 0, because the logged compile error it also expects is not observable from a unit test. `no-hardcoded-strings` fails because `displayName` returns English literals meant for a picker. `data-integrity` is partial because decoding is strict (a missing key or unknown strategy throws rather than silently defaulting), but the context accepts duplicate `windowID`s, a stale `lastFocusedWindowID` and an unparsed `color` string, leaving those invariants to the managing layer.

