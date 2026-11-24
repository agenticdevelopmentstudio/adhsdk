
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`screen-reader-support`, `keyboard-navigable` and `semantic-markup` pass because the root is a native anchor with an `href`, an `aria-label`, and an `aria-hidden` glyph. `touch-target-size` is partial because the visible circle is 22px by default and the source adds no larger hit area. `separation-of-concerns` passes because the component holds only markup and a class name, and all styling lives in a separate opt-in stylesheet. `unit-test-coverage` is partial because `ProfileInfoButton.test.tsx` covers vectors 001 to 007, 012 and 014, while 008 to 011 (placement, size, theme tokens, hover and focus highlight) and 013 (overflow clipping) are skipped: they depend on real layout, `var()` resolution and pseudo-class styling that jsdom does not provide.
