
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | platform-compliance |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | platform-compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | internationalization |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

Separation-of-concerns passes because the control holds only a `Spacing`
value and an `onChange` closure, with all settings/persistence concerns
pushed to `SpacingSettingsBinding`, a separate type (per the type's own doc
comment). Platform-theming passes because every color this file paints
comes from `SemanticPalette` tokens, never a raw literal.
Native-controls-preference and platform-design-language pass because number
entry uses stock `NSTextField`/`NSStepper`, and Reset uses a stock
`NSButton` with the standard rounded/small bezel. Keyboard-navigable passes
because every number is reachable and editable by Tab plus the arrow keys
(tab-order-is-picture-order, arrow-keys-adjust-focused-field).
Screen-reader-support is partial because the arrow buttons carry an
accessible description but the number fields and steppers do not (see
Accessibility: Label requirements). Contrast-ratio is partial because the
diagram's borders and fills are theme-token-driven but have no verified or
Increase-Contrast-aware path (see the open question on
minimum-contrast-ratio). String-externalization fails because every
user-facing string in this file is a hardcoded literal with no
localization mechanism (see Localization).

`unit-test-coverage` is `partial`: `UI/SpacingTests.swift` pins the arithmetic and layout of the control (`testTheGrowingArrowAddsRoomAndTheShrinkingArrowTakesItAway`, `testATypedNumberIsClampedRatherThanRefused`, and the `SpacingControlLayoutTests` cases for number placement and non-overlap), but nothing there exercises `onChange` firing rules, theme re-application or the Reset button.

