
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | failed | Security |
| [adc.check.security.content-security-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/342ea2ea-fb37-5746-9ccd-e81d3d593996) | partial | Security |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`semantic-markup` passes because the `as` prop lets the host choose the correct landmark element for the rendered content. `dynamic-type-support` is partial because text sizing is inherited from the host's prose theme, which the source neither controls nor can vouch for. `input-sanitization` fails because the component explicitly performs no sanitization on the `html` prop by design (see **No direct support for HTML sanitization**). `content-security-policy` is partial because DocArticle renders raw HTML without enforcing a policy itself, leaving CSP enforcement to the host page. `separation-of-concerns` passes because `DocArticle` only forwards the `html` and `as` props with no business logic; `unit-test-coverage` passes because `docArticle.test.tsx` imports `DocArticle` directly and exercises its behavior with meaningful assertions.

