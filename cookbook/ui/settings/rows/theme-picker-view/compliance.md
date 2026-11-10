
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`native-controls-preference` and `platform-design-language` pass because the
component defers entirely to `PopupMenuChoiceView`'s and `ThemePreviewView`'s
own native-control choices rather than introducing new UI of its own.
`keyboard-navigable` and `screen-reader-support` are `partial`: this file
adds no keyboard or screen-reader behavior of its own, inheriting the
popup's own inherited `NSPopUpButton` navigation and its already-linked
accessible name from `PopupMenuChoiceView.swift` (see
[adhsdk.ingredient.ui.settings.rows.popup-menu-choice-view](cookbook:3a3e4da0-e900-4281-a19c-e29cbd34cbab)), but the popup's visible
title is the unlocalized `"Theme"` default this file cannot override (see
Localization) and the row itself offers no disable path (see States,
Disabled), so this file's own compliance can't be called a full pass.
`idempotent-operations` is `partial` for the same reason: it holds only
because `ThemeManager.reload()`'s `theme != currentTheme` guard
(`ThemeManager.swift`) makes repeated selections of the same theme a
no-op for the preview (see Edge Cases) — a property of `ThemeManager`, not
of anything `ThemePickerView.swift` itself guarantees. `separation-of-concerns`
passes because the preview refresh path is fully decoupled from the
selection commit path (see Design Decisions).

`unit-test-coverage` is `partial` because `ThemeUITests.swift` (`picker`) constructs a `ThemePickerView` and asserts only that it has subviews; selection, preview coupling and persistence are not asserted.

