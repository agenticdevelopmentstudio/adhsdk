
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | internationalization |

Keyboard-navigable is partial
because `closeButton` is a real `NSButton` and gets standard key-view-loop
operability for free, but selecting the card itself has no keyboard path in
this file — that is the hosting `TabItemHostView`'s concern (see the
`multi-tabbed-view-controller` recipe's own `keyboard-navigable: failed`
finding). Screen-reader-support is partial because accessibility identifiers
and status-symbol labels are set explicitly, but the card sets no
`accessibilityRole` and groups nothing for VoiceOver (see Accessibility).
Reduced-motion is failed for the gap documented in Accessibility Options.
String-externalization is failed because `closeButton`'s "Close" accessibility
description is a hardcoded English literal (see Localization).

Separation-of-concerns is passed: `TabPaneView` only draws the card (background, labels, status symbols, close control) and exposes its depth and callbacks, while content values come from `TabPaneDataSource` and user intent leaves through `TabPaneDelegate`, so the card holds no tab-ordering or data-fetching policy. Unit-test-coverage is partial: `TabPaneViewControllerTests.swift` and `TabCardStackTests.swift` drive the card through its controller (label content, measured size, close button placement, depth-dependent painting and animation), but there is no test file for `TabPaneView` itself and several edge-specific drawing details are untested.

