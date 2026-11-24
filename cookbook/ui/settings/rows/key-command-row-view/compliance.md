
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | platform-compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

The `passed` rows rest on source facts that are unconditional: the row is
`@MainActor`-isolated throughout, composes native `NSSwitch`/AppKit
controls per platform HIG, sets accessibility identifiers on the capture
field and toggle, and keeps business logic (edit/commit/toggle state) out
of its own presentation code, delegating persistence to the registry. The
`partial` rows rest on the Accessibility section's gaps: the
toggle is labeled via `setAccessibilityTitleUIElement`, but the capture
field has only an accessibility identifier and no accessibility label, and
no state change posts an `NSAccessibility` announcement, so screen-reader
support, keyboard/focus behavior around the capture field, and label
completeness are not fully implemented. `no-hardcoded-strings` is `failed`
because every user-facing string
this file introduces is a Swift literal with no localization mechanism, as
the Localization section states.

`unit-test-coverage` is `partial` because `KeyCommandBehaviourTests.swift` builds `KeyCommandRowView` rows against a registry and asserts on recording over a shipped-off command (it switches on), the switch refusing to re-enable a taken chord, and the recorder's Shift-Tab behavior, and `KeyCommandsPanelHierarchyTests.swift` asserts on the rows' place in the panel; there is no dedicated `KeyCommandRowViewTests` file and layout and reset paths are not asserted.

