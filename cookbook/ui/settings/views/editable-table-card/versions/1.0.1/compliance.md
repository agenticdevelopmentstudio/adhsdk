
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Separation-of-concerns is partial: the card keeps storage, sorting and add/remove policy with the owner through callbacks, but it also parses typed day, time, duration and money text and manages edit deferral in one large view. Unit-test-coverage is partial: `EditableTableCardTests.swift`, `EditableTableCardTypedEditTests.swift`, `EditableTableCardUpdateTests.swift` and `EditableTableCardFooterTests.swift` cover columns, sorting, rows, toggles, edits, held reloads, binding to rows and columns, typed edits and rejections, row updates, selection, recycling and footer controls; indicator accessibility labels, the locale and time zone reload and the mismatched cell are not tested.

