
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Native-controls-preference and platform-design-language pass because the
component is a stock pull-down/menu control with no custom drawing.
Keyboard-navigable passes on the platform's inherited keyboard support for
this control (Space/Return opens the menu; arrow keys and type-to-select
navigate it), unmodified by this component. Screen-reader-support passes
because the accessible name is the same title-based string always shown on
screen, and that string always states both the filtered axis and the
current selection (see **Label requirements** under Accessibility).
Contrast-ratio is `partial` because the resolved theme colors are never
checked for contrast in source (see the open question on **contrast**).
String-externalization is failed because the "Any" and "{n} selected"
strings are hardcoded English literals with no localization key (see
Localization).

`separation-of-concerns` passes because the control owns only the menu, the title summary and the checkmarks, takes its choices as caller-supplied id/title/detail values and reports changes through `onChange`, leaving the meaning of an id to the caller. `unit-test-coverage` is `failed`: a search of the Apple test targets finds no test file for `MultiChoiceFilterButton`, so vectors 001 through 026 are unpinned by automated tests.

