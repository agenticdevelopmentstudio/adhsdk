
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | accessibility |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |

`native-controls-preference` and `screen-reader-support` pass because
`ConditionalView` is a plain `NSView` that relies entirely on AppKit's own
`isHidden` to remove `child` from both the view and accessibility trees;
`idempotent-operations` passes via the `hidden != self.isHidden` guard in
`applyVisibility`; `separation-of-concerns` passes because `ConditionalView`
manages only visibility, delegating all appearance and accessibility to
`child`.

`unit-test-coverage` is partial: `EditableTableCardUpdateTests.swift` has one test (`explanationFollowsAConditionalSetting`) that builds a `ConditionalView` around a `UserSetting<Bool>` and asserts the child hides and reopens when the setting flips, but no dedicated `ConditionalViewTests.swift` exists, and the initial-visibility, predicate, constructor-trap and idempotent-visibility paths are untested.

