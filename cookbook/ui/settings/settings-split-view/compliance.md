
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

Statuses rest on: this file delegating row
rendering to `PanelListViewController`, help chrome to `PanelHostView`, and
scroll wrapping to `PanelScrollView` rather than reimplementing any of them
(separation-of-concerns); the search field's arrow-key redirect and the
unmodified standard `NSSplitViewController` tab order (keyboard-navigable);
`native-controls-preference` resting on this file composing only stock
`NSSplitViewController`/`NSSplitViewItem`/`NSSearchField` behavior with no
custom-drawn chrome. `screen-reader-support` is `partial`: the search
field's accessible description is the AppKit-default `placeholderString`,
but that placeholder is the unlocalized `"Search"` literal documented under
Localization, so a non-English VoiceOver user would hear an English word
regardless of the app's language.

`unit-test-coverage` is partial: `ThemedSplitViewOrientationTests.swift` builds `SplitViewController` and asserts its split view is side by side, and the collaborators it delegates to are tested separately (`SettingsSearchIndexTests.swift`, `SettingsNavigationHistoryTests.swift`), but panel add/remove, selection, the search redirect, help routing and sidebar autosave have no test of their own.

