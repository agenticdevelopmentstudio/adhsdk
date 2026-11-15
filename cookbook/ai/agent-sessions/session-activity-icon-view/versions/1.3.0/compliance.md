
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

`screen-reader-support` is `passed` because `describeState()` unconditionally
sets a meaningful accessibility label for every state (see
**state-based-label-and-tooltip**). `contrast-ratio` is `partial` because
the tint's contrast against a session row's background cannot be computed
from this file alone (see **theme-owned-tint-contrast** and its Design Decision).
`reduced-motion` is `failed` because no code path here checks a Reduce
Motion signal before starting the spin or pulse animation (see
Accessibility Options → Reduce Motion). `no-hardcoded-strings` is `failed`
because the four accessibility label/tooltip strings are plain `String`
literals with no localization key (see Localization).

`separation-of-concerns` passes because `SessionWatcherActivityIconView` only draws and animates one glyph for a state it is handed; it reads no session data, performs no I/O and owns no layout beyond its own bounds. `unit-test-coverage` is partial: `SessionWatcherActivityIconViewTests.swift` covers the working glyph spinning about its centre, staying centred when the row moves it, and swapping the animation on state changes (that test also asserts the idle accessibility label), but nothing asserts the working, waiting or summarizing labels, the tooltip or the tint role.

