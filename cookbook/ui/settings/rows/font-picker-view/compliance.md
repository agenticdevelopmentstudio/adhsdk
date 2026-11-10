
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | platform-compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | accessibility |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | internationalization |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`native-controls-preference` and `platform-design-language` pass because the
component defers to `FontChooserButton`'s own use of the system font panel
rather than building a second font browser. `keyboard-navigable` passes on
`NSButton`'s inherited Tab/Space/Return handling. `screen-reader-support` is
`partial`: `button`'s own accessible name (its `title`) is meaningful, but
`FontPickerView.swift` sets no `accessibilityLabel`/`setAccessibilityTitleUIElement`
linking `button` to the row's descriptive `label`, unlike the sibling
`CheckboxView`/`NumberFieldView`/`PopupMenuChoiceView` rows (see Label
requirements under Accessibility). `contrast-ratio` is `partial`: the
resolved contrast of the 40%-alpha disabled label cannot be determined
from this file alone (see the open question on minimum-contrast-ratio
under Accessibility).
`idempotent-operations` passes because repeated `sync()` calls always
converge to the same observable state (see Edge Cases).
`separation-of-concerns` passes because the component stores no font of its
own beyond its reference to `viewModel`, and delegates all font-resolution
fallback to `FontViewModel.font` (see **delegates-font-resolution-fallback**).
`string-externalization` fails because `describe(_:installed:)`
builds its output from hardcoded, unlocalized string fragments (see
Localization).

No test in the repository's test targets constructs `FontPickerView`, so `unit-test-coverage` is `failed`: a search of `AgenticDeveloperHubSDKMacOSTests` and the other test targets for the type name finds nothing. `FontChooserButtonTests.swift` covers only the button this row composes, not the row's binding, resync or dimming.

