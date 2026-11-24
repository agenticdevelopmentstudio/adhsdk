
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | partial | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on `PaneViewController.swift` and `PaneSpacingOverride.swift` as built: the gear and spacing-reset buttons carry real accessibility labels and identifiers, but no `NSAccessibility` notification is posted anywhere when the title, minimize state, or zoom state changes (`screen-reader-support`, partial); every user-facing string (`fallbackTitle`, the gear's tooltip/label, the "Settings…" and "Use Default" titles) is a hardcoded Swift literal with no localization key (`string-externalization`, failed); `PaneSpacingOverride`'s `JSONEncoder`/`JSONDecoder` calls are wrapped in `try?` so a corrupt or unwritable row is silently dropped rather than reported (`data-integrity`, partial); and the default `EphemeralPaneStateStore` keeps state in memory only, so nothing survives an actual process restart unless the caller injects a persistent store (`state-recovery`, partial).

`separation-of-concerns` passes because `PaneViewController` supplies only the title bar, content hosting and host-mediated close, minimize, zoom and restore actions; what the actions do is decided by the host. `unit-test-coverage` is `partial`: `Panes/PaneViewControllerTests.swift` and `Panes/PaneCapabilitiesTests.swift` cover the chrome and capabilities, but not every vector.

