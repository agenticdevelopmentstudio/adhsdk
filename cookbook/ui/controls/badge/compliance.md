
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

This status rests on `Badge.swift`: `contrastingTextColor(on:)` uses an
unverified perceptual-luminance heuristic rather than a WCAG contrast-ratio
computation, so a specific minimum ratio cannot be confirmed from the source
alone (`contrast-ratio`).

`separation-of-concerns` passes because `Badge.swift` owns only the pill shape, padding and text styling and takes its text, color and style from the caller rather than deriving them from a status vocabulary of its own. `unit-test-coverage` is `partial`: `UI/BadgeConformanceTests.swift` covers badge-001 through badge-013 and badge-016; badge-014 (`@MainActor` isolation is enforced at build time) and badge-015 (the archived-construction refusal calls `fatalError` and cannot be caught) are skipped.

