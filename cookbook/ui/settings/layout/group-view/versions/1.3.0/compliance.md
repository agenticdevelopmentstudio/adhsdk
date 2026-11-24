
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | Reliability |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |

Statuses rest on `GroupView.swift`: `native-controls-preference` reflects the
card being built from `NSStackView`/`ThemedBox` rather than a custom-drawn
control; `idempotent-operations` is `partial` because `viewDidMoveToSuperview`
activates a fresh width constraint on every attach without removing one from
a prior superview (see Design Decisions); and `screen-reader-support` is
`partial` because no accessibility grouping ties the header to
`cardView`/`rowStack` (see Accessibility).

Separation-of-concerns is passed: `GroupView` owns only the card layout (a title header, rows with separators and self-hiding rows) via its private `CardRow`, while row content, explanations and visibility come from the views added to it. Unit-test-coverage is partial: no dedicated `GroupViewTests.swift` exists, but `EditableTableCardUpdateTests.swift` (rows reopening around a hidden `ExplanationView` and a `ConditionalView`), `SettingsSearchIndexTests.swift` and `KeyCommandsPanelHierarchyTests.swift` construct real `GroupView` cards and assert on their contents and nesting; separator updates and the width-constraint behavior are untested.

