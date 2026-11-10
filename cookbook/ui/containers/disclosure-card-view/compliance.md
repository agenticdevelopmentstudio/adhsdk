
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`keyboard-navigable`, `native-controls-preference`, and
`platform-design-language` rest on what the source visibly does (the native
`NSButton`/`NSStackView` controls); `screen-reader-support` and `contrast-ratio`
are `partial` because the source cannot settle, respectively, the disclosure
label's staleness between a click and the host's rebuild (see
`does-not-self-mutate-on-toggle`) and each shipped theme's actual resolved
contrast ratios; `no-hardcoded-strings` is `failed` because
`"Show details"`/`"Hide details"` are English literals with no
localization key (see Localization).

`separation-of-concerns` passes because the card is a pure presentation view: it takes its content, title, summary and palette as inputs, reports a click only through `onToggle`, and leaves fold state to a host-owned `CardFoldMemory`, so no persistence or navigation logic lives in the view (see `does-not-self-mutate-on-toggle`). `unit-test-coverage` is `partial`: `UI/DisclosureCardTests.swift` pins the fold-memory contract, the card's width and height rules (`testAFoldedCardIsExactlyAsWideAsAnOpenOne`, `testACardIsNeverNarrowerThanTheContentItIsHiding`), the title status symbol and its palette tint and spoken label (`testTheSymbolAfterTheNameIsSpokenAndTintedFromTheLivePalette`) and the corner badge's spoken label, but nothing there exercises the surface, outline, titlebar and text palette mapping, the toggle callback, or the disclosure control's labels.

