
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy & Data |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`screen-reader-support` is partial because the refresh button has no explicit
`.accessibilityLabel` (see **refresh-button-label**);
`keyboard-navigable` passes because every interactive element is a standard,
keyboard-focusable `Toggle`/`Button`. `contrast-ratio` and
`no-hardcoded-strings`/`string-externalization` are partial for the same two
source-documented exceptions: the context badge's `Color(hex: ctx.color) ??
.blue` fallback sits outside the theme palette, and the `(untitled)` fallback
is routed through `Text`'s verbatim `String` initializer instead of a
localization key. `dynamic-type-support` is partial because the source
resolves every font through `theme.font(_:)` and this file cannot tell
whether that palette scales with the system text-size setting.
`data-minimization` passes because the Privacy section shows the view reads
only currently-running window data needed for display, filtered by
`appState.settings.hiddenApps`, and persists nothing.

`separation-of-concerns` is `partial` because `WindowExplorerView` renders the grouped list but its `refreshAsync` also enumerates windows, filters them by size, visibility and hidden apps, and enriches titles through the accessibility API inside the view, work that belongs in a model or service the view reads from. `unit-test-coverage` is `failed` because no test references `WindowExplorerView` or `AppWindowGroup` anywhere in the repository's test targets.

