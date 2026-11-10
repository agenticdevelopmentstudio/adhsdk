
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`keyboard-navigable` and `reduced-motion` are omitted: `ThemePreviewView.swift`
has no `NSControl`, target-action, or interactive element of any kind (see
States/Pressed) and no `NSAnimationContext`/animator proxy or transition of
any kind (see Accessibility Options/Reduce Motion), so neither check applies.
The remaining statuses rest on `ThemePreviewView.swift` itself: every color
and role-styled font is read through `SemanticPalette`/`TerminalAppearance`
role lookups, never a raw literal (the passed checks above); no
`setAccessibilityRole`/`setAccessibilityElement`/label override is set on any
container view, leaving VoiceOver labeling only partially met by AppKit's
default static-text role on each label (`screen-reader-support`, partial);
and every visible string is a
literal passed to `NSTextField(labelWithString:)`, never routed through
`NSLocalizedString` (`no-hardcoded-strings`, failed).

`unit-test-coverage` is `partial` because `ThemeUITests.swift` (`preview`) constructs a `ThemePreviewView` for a built-in theme, calls `show` with another and asserts only that it has subviews; the rendered sample content is not asserted.

