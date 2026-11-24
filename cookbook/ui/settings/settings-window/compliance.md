
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`screen-reader-support` and `keyboard-navigable` rest on the Accessibility
section's Label requirements and Keyboard/focus bullets (explicit
accessibility labels/descriptions on the navigation control and help button;
ordinary keyboard-focusable AppKit controls). `dynamic-type-support` and
`contrast-ratio` are `partial` because the source reads fonts and colors
from the shared theme palette but this file neither asserts nor decides
scaling or contrast itself (see the open question on
minimum-contrast-ratio).
`no-hardcoded-strings` and `string-externalization` are `failed` because
every user-facing string this file passes to AppKit is a literal, not a
localization key (see Localization).

`separation-of-concerns` passes because `SettingsWindow` owns only window chrome (the toolbar with its back/forward control, panel-title item and help button, and activation) and hands every content concern to `SplitViewController`, the panel list and the panels, with navigation history held in `SettingsNavigationHistory` rather than in the window. `unit-test-coverage` is failed because no test file exercises `SettingsWindow`: the only test that mentions it, `ThemedSplitViewOrientationTests.swift`, builds a `SplitViewController` and never the window controller, and the toolbar, navigation-change callback and activation behavior are untested.

