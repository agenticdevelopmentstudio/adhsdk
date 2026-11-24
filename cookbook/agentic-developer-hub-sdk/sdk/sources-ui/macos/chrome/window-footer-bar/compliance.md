
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | failed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source: `dynamic-type-support` fails because `WindowFooterBar.height` is a hardcoded 22pt constant with no logic that grows the bar or the label for larger text (see the **Large system text size** edge case); `contrast-ratio` is partial because the source applies theme-role colors (elevated surface, border, secondary text) but the actual color values behind those roles are defined outside this file, so the resulting contrast cannot be confirmed here. `separation-of-concerns` passes because the bar takes only a status string and knows nothing of what a pane or a path is — the window formats that and hands over the result; `unit-test-coverage` passes on `WindowFooterBarTests.swift`'s exercise of the status round-trip, its tooltip, its identifier, and the trailing accessory slot.

