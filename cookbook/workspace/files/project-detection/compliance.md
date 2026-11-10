
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |

Notes: unit-test-coverage is partial because `LanguageDetectionTests.swift`
covers `LanguageDetection.language(for:)`'s built-in and custom-override
paths (three tests) but not `lspLanguageId(for:)`, while `IDEDetector.swift`
— `IDEType`, `IDEProject`, and every function on `IDEDetector` — has no
test file anywhere in the repository (only compiled build artifacts were
found, no source test). separation-of-concerns passes because
`IDEDetector.swift` and `LanguageDetection.swift` are two independently
named files under `.../Model/Detection/`, each with one detection
responsibility, and `LanguageDetection` itself keeps "consult the user's
override" and "fall back to the built-in table" as two distinct steps
rather than one entangled one. no-hardcoded-strings fails because
`IDEType.displayName`/`systemImageName` and the `"VS Code"` literal are
English-only literals with no localization mechanism (see Localization).
fault-tolerance passes because every file-system read in `scan`,
`matchMarkers`, and `detectJetBrainsType` is wrapped in `try?`, so an
unreadable directory or unexpected entry degrades to an empty or partial
result rather than throwing or crashing (see Edge Cases).

