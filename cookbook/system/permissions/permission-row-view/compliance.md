
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | partial | Platform Compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`native-controls-preference` is `passed` because every element is a stock
`NSButton`/`NSTextField`/`NSImageView`/`NSStackView`; `platform-design-language`
and `contrast-ratio` are `partial` because `buildLayout()` fills and borders
the card with fixed, non-semantic `NSColor.white.withAlphaComponent(...)`
values (see the dark-only Design Decision above and the open question on
contrast) rather than an appearance-adaptive token, so neither HIG
conformance nor a 4.5:1 contrast ratio can be confirmed for every host
background; `keyboard-navigable` is `passed` because the action button is an
unmodified `NSButton`, which keeps AppKit's native keyboard focus and
activation (see **keyboard-activates-action**).

`separation-of-concerns` is `passed` because `PermissionRowView` only renders one card and reports the action; the status read goes through the injected `PermissionChecking` and the grant flow through the `onAction` callback, so neither is decided inside the view. `unit-test-coverage` is `passed` because `Tests/AgenticDeveloperHubSDKPermissionsUITests/PermissionRowViewTests.swift` exercises the row with a stub checker: the Granted, Not Granted and Unknown labels, the action offered for granted and non-granted rows, the status the action reports, and a refresh cancelled mid-read.

