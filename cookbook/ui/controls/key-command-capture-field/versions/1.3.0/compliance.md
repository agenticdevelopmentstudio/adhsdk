
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | failed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`native-controls-preference` is passed, not failed: the component
deliberately avoids the native `NSTextField` control for the reason recorded
in Design Decisions above (a field editor would eat the chords being
recorded), so the deviation is justified rather than an oversight.
`screen-reader-support` is failed because the source implements no
accessibility role, label, or state announcement at all (see Accessibility
above). `contrast-ratio` is partial per the open question on
minimum-contrast-ratio in Accessibility above: the actual colors are
theme-resolved at runtime and cannot be checked against a ratio from this
source file alone. No catalog check covers the one-color-only transition
described under Differentiate Without Color in
Accessibility Options above; it is not represented in this table.
`no-hardcoded-strings` is failed because of the two unlocalized literals
recorded under Localization above.

`separation-of-concerns` passes because the field only turns key events into `onCapture`, `onCancel` and `onCommit` callbacks and displays a shortcut value; what a captured chord means, and whether it conflicts with another, is decided by the owning panel. `unit-test-coverage` is `partial`: `KeyCommands/KeyCommandBehaviourTests.swift` hosts a `KeyCommandCaptureField` (its `recordingField()` helper) and drives its key handling directly (`testShiftTabLeavesTheRecorderInsteadOfBeingRecorded`, `testReturnCommitsInsteadOfBeingRecorded`) and its `onCapture`/`onCommit` callbacks through the panel row, but nothing exercises the Escape cancel, command-chord capture through the key-equivalent path, focus-driven recording state, or theming.

