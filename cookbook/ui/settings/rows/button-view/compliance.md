
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | failed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

The `passed` statuses rest on `ButtonView` using an unmodified `NSButton` for its role, label, keyboard handling, and system-chrome contrast, and on `ButtonView` defining no string literals of its own. `dynamic-type-support` is `failed` because `button.font` is never set to a text-style-based font (e.g. `NSFont.preferredFont(forTextStyle:)`), so its title does not scale with the system text-size setting. `touch-target-size` is `passed` on macOS: the button keeps the system control metrics (see **Minimum tap target** under Accessibility).

`separation-of-concerns` passes because `ButtonView` only places an `NSButton` in a row according to its `Placement` and forwards the press to the view model's `wasPressedCallback`; what the press does belongs entirely to the caller's `ButtonViewModel`. No test in the repository's test targets constructs `ButtonView`, so `unit-test-coverage` is `failed`: a search of `AgenticDeveloperHubSDKMacOSTests` and the other test targets for the type name finds nothing.

