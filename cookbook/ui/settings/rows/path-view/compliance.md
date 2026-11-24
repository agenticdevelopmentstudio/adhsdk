
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on: the label's font tracking the theme's `.caption` role and
`sizeScale` (`dynamic-type-support`, per Appearance above); the enforced
3.0-minimum `.secondaryText` contrast that cannot be confirmed at 4.5:1 for
every theme (`contrast-ratio`, per the open question on
minimum-contrast-ratio in Accessibility above); the caption-prefixed visible
text versus the raw-`path`-only accessibility value, with no accessibility
label filling the gap (`screen-reader-support`, per the Accessibility
section's Label requirements above); and the hardcoded `": "`
separator literal at `PathView.swift` (`no-hardcoded-strings`, per
Localization above).

`separation-of-concerns` passes because `PathView` has one job, presenting a single already-known path string as one truncating line; it reads no filesystem, owns no setting and has no view model, and takes its label styling from the shared `makeValueLabel` factory. `unit-test-coverage` passes because `PathViewTests.swift` exercises the view directly: the whole path survives truncation in the tooltip, accessibility value and selectable text, the label is one line truncated in the middle, the caption is drawn at the head, and a long path yields its width instead of widening the window.

