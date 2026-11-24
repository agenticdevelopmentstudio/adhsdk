
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | platform-compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | accessibility |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`native-controls-preference` and `platform-design-language` pass because every
control is a stock AppKit `NSButton`/`NSTextField`; `keyboard-navigable` is
`partial` because source sets no explicit key-view-loop or Full Keyboard
Access handling of its own (only AppKit's default `NSControl` tab behavior);
`semantic-markup` stays `partial` because Accessibility documents that
source implements no accessibility group linkage between the heading label
and the radio buttons beneath it (see Label requirements);
`idempotent-operations` passes on `skips-redundant-commits`; and
`separation-of-concerns` passes because Behavioral Requirements now state
platform-neutral behavior, with the AppKit-specific mechanics confined to
Platform Notes.

No test in the repository's test targets constructs `RadioButtonChoiceView`, so `unit-test-coverage` is `failed`: a search of `AgenticDeveloperHubSDKMacOSTests` and the other test targets for the type name finds nothing.

