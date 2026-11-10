
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |

`keyboard-navigable` passes because the component overrides no
keyboard-handling behavior of the platform's default; keyboard scrolling
and screen-reader navigation are both provided, unmodified, by the
inherited scroll-container behavior (see Accessibility).

Separation-of-concerns is passed: `PanelScrollView` is only the scroll host, pinning its flipped document's width to the viewport and leaving all content to the panels it hosts. Unit-test-coverage is failed: no test in the repository's test targets references `PanelScrollView`.

