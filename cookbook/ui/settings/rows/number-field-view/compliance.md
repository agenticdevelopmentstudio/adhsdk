
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | platform-compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`native-controls-preference`, `platform-design-language`, `keyboard-navigable`,
`idempotent-operations`, and `separation-of-concerns` rest on the source's use
of a stock `NSTextField`'s own keyboard-and-focus behavior, its
skips-redundant-commits guard, and its single-responsibility split between the
generic view and the `SettingsNumberValue` parsing contract; `screen-reader-support`
is `partial` because `setAccessibilityTitleUIElement` gives the field a
spoken name, but an unparseable-text revert (**reverts-on-unparseable-text**)
changes `textField.stringValue` with no explicit `NSAccessibility` announcement
in source, so whether VoiceOver notices the reverted value while the field is
focused is left to AppKit's own, unverified-in-source, default behavior.

`unit-test-coverage` is `partial` because `ConfigurationContributionPointTests.swift` constructs `NumberFieldView` for both `Int` and `Double`, commits typed text, asserts a `maximum` clamp with the field text rewritten to the clamped value, and asserts that non-numeric text reverts the field; there is no dedicated test file and layout, theming and external-change resync are not asserted.

