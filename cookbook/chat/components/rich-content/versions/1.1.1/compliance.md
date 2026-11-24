
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.privacy-and-data.third-party-disclosure](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/036c9768-1c60-543d-b692-4adb3d3c884f) | partial | Privacy & Data |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The Security and Accessibility statuses rest on `safeHref()`'s protocol allowlist and the native `<a>`/`<img>` elements shown in `RichContent.tsx`, which need no extra ARIA or keyboard wiring. The Privacy & Data status is partial because loading an image from an arbitrary `src` is standard, undisclosed browser behavior the component does not gate (see **Image-fetch exposure** under Privacy). The security-critical `safeHref()` scheme allowlist is a standalone, independently testable function rather than logic tangled into the JSX (separation-of-concerns passed); `RichContent.test.tsx` directly exercises both the image-gating behavior and the `safeHref` protocol allowlist, including the `javascript:` rejection (unit-test-coverage passed).

