
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on `SettingsPanelViewController.swift` itself: it composes
only native `NSViewController`/`NSHostingView` APIs, never reimplementing
their layout (`native-controls-preference`: passed), but it sets no
accessibility role or label of its own — that responsibility belongs to the
`GroupView`s and SwiftUI content a subclass hosts — so `screen-reader-support`
is only `partial` here, not exercised or violated by this file.

`separation-of-concerns` passes because `SettingsPanelViewController` only holds a descriptor, exposes its panel-view content, forwards groups to it, and offers overridable help/search/scroll defaults; layout, scrolling and help chrome live in the panel view, panel host and split view. `unit-test-coverage` is partial because there is no test file for `SettingsPanelViewController` itself: its `searchKeywords` and help-content overrides are exercised through the `TestPanel` subclass in `SettingsSearchIndexTests.swift`, and `SettingsCardViewsTests.swift` calls its `hostingView(for:)` helper, but the descriptor-immutability, default-descriptor, add-group and hosts-own-scroll defaults have no test.

