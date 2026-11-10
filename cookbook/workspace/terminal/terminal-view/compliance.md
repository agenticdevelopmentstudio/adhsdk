
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | failed | Platform Compliance |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |

`separation-of-concerns` passes because the view only reconciles the caret's appearance with the active-pane state and delegates terminal emulation, input and focus to the underlying terminal engine; `unit-test-coverage` fails because no test under the repository's test targets references `ThemedTerminalView` or `CaretAppearance`. `platform-theming` fails because `CaretAppearance.color` and `CaretAppearance.textColor` default to the literal `NSColor.white` rather than a semantic, theme-aware color token, so the caret's own defaults do not adapt to the app's theme (see the corresponding Design Decision). `contrast-ratio` is `partial`: the caret's colors are applied verbatim from caller input with no contrast computation in this file, so conformance depends entirely on what the caller supplies — see the open question on contrast-ratio under Accessibility. `keyboard-navigable` and `screen-reader-support` are `partial`: `ThemedTerminalView` adds no keyboard handling, role, or label of its own and overrides none of `LocalProcessTerminalView`'s, but this file gives no evidence of what `LocalProcessTerminalView` itself provides for either, so full conformance cannot be confirmed from this source alone.

