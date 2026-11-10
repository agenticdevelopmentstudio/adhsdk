
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | failed | Accessibility |

Both statuses rest on `ExplanationView.swift`'s reliance on the theme's
`.secondaryText`/`.caption` roles: contrast is partial because
`SemanticPalette` enforces only a 3.0 minimum ratio (see Accessibility
above), and dynamic-type-support fails because
`ThemeTypography+NSFont.swift`'s `nsFont(scaledSize:)` builds fonts through
fixed-point-size calls (`NSFont.systemFont(ofSize:weight:)` or a named-family
lookup at an explicit size) rather than `NSFont.preferredFont(forTextStyle:)`
or any observation of the system's content-size-category setting.

Separation-of-concerns is passed: `ExplanationView` only wraps a themed label and exposes `text`, `isHidden` and the visibility callback, leaving colors to the theme and row layout to its container. Unit-test-coverage is partial: `EditableTableCardUpdateTests.swift` has a test (`an ExplanationView hidden before it is placed reopens its row when shown`) and `ExtensionsSettingsPanelTests.swift` reads the text of explanations, but no dedicated `ExplanationViewTests.swift` exists and wrapping, sizing and constructor-trap behavior are untested.

