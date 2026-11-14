
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

Separation of concerns passes because the file holds only override values, the caret-shape enum and `isEmpty`; resolution against settings, tone derivation and the SwiftTerm mapping live in other files. Unit-test coverage fails because the only test that names these types (`BubbleTruncationTests`) uses `ThemeTerminalOptions` as a fixture, so the `isEmpty` logic, the synthesized coding and the shape raw values have no direct assertions. No-hardcoded-strings fails because `TerminalCursorShape.label` returns English literals with glyphs, not table lookups. Data integrity is partial: the structs store padding, font size and font name without any range or existence check, and an unknown cursor-shape string fails the whole theme decode.

