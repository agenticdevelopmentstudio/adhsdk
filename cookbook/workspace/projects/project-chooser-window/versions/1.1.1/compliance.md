
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | Performance |

Notes: separation-of-concerns passes because `ProjectChooserWindow` and its
content view controller own only the modal session, the button pair, and
the choose/cancel wiring between them — the project list itself, its
filtering, and its selection model belong entirely to
`ProjectBrowserViewController`, and the registry data belongs to
`ProjectsCoordinator`; neither is duplicated here. unit-test-coverage fails
because no test file exercises `ProjectChooserWindow` or
`ProjectChooserContentViewController` at all — `packages/apple/AgenticDeveloperHubSDK/Tests`
has no `ProjectChooserWindowTests.swift` or equivalent, so none of this
recipe's requirements (the onFinish wiring, the modal-identity guard on
close, the button enablement synchronization) has automated coverage.
native-controls-preference passes for the reason the source's own doc
comment gives: Cancel and Open are stock `NSButton`s, deliberately, rather
than a hand-drawn pair. platform-design-language passes because the window
uses a standard titled/closable/resizable `NSWindow`, a centered starting
position, and the Return-as-default-button / Escape-as-Cancel convention
every AppKit dialog follows. fault-tolerance passes because every guard in
this file (`runModal()`'s `guard let window`, `windowWillClose(_:)`'s
`guard NSApp.modalWindow === window`, the disabled-until-selected Open
button) fails safe — into a no-op or a `nil` result — rather than crashing
or corrupting `chosen`. main-thread-freedom passes because this file
performs no computation, file I/O, or network call of its own alongside
its UI work; the only blocking call it makes, `NSApp.runModal(for:)`, is the
platform's own intentional modal wait, not work this file could move off
the main thread.

