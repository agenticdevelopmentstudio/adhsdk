
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

The declaration holds only a key, a type and a default, and leaves storage to the settings store, matching to `GitIgnoreMatcher`, and display to the macOS view controllers (separation-of-concerns: passed). The matcher that interprets the list has its own `GitIgnoreMatcherTests`, and `LayeredSettingsStoreTests` covers the store, but no test in the source reads or writes `fileBrowserExcludedPatterns` itself, so the key name and default are asserted by no test (unit-test-coverage: partial). The setting stores only what the user types, with an empty default (data-minimization: passed).

