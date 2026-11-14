
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Rationale, one line per check:

- semantic-markup (passed): the `aria-live="polite"` region in `TypingIndicator.tsx` is updated only on phase and utterance changes.
- reduced-motion (failed): no reduced-motion check wraps the dot-pulse timers, the phase-driven glyph timer, or web's colorful hue cycle, in any of the three sources.
- string-externalization, no-hardcoded-strings, locale-aware-formatting (failed): the `"…"`, `"for"` and `"s"` strings and the fixed `"for {n}s"` elapsed-time template are literals in `TypingIndicator.tsx`, `ThinkingIndicatorView.swift` and `MobileThinkingIndicatorView.swift`.
- text-expansion-tolerance (partial): the tail-truncating layout on web and AppKit/UIKit tolerates overflow without crashing but is not verified against a 200% expansion target.
- dynamic-type-support, contrast-ratio (partial): the semantic-palette caption font and the random `colorful` hue are not checked against Dynamic Type or the active theme's contrast at render time.
- rtl-layout-support (partial): the glyph-then-word layout order is fixed and none of the three sources adapts it for RTL locales.
- unicode-support (passed): Swift `String`/`NSAttributedString` and JavaScript strings are full-Unicode-capable.
- separation-of-concerns (partial): the native views delegate the phase state machine to `ThinkingPhase.Machine` and word selection to `ShuffleBag`, but `TypingIndicator.tsx` implements timers, word-bag draws and the elapsed-time calculation inline inside `ThinkingStatus`.
- unit-test-coverage (passed): `TypingIndicator.test.tsx`, `ThinkingIndicatorViewTests.swift` and `MobileThinkingIndicatorViewTests.swift` exercise this component's behavior.
