
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | security |

The component keeps one concern: it decides whether the script element exists and leaves the script's content, the appearance logic and the client-side follow-up to its callers and to `AppearanceScope`, so separation of concerns passes. `DocumentLoadScript.test.tsx` covers the server markup, the client mount with no React error, and hydration without a mismatch, which are the component's three paths, so unit-test coverage passes. The `code` prop is inserted unescaped and the source documents this as a trusted-callers-only contract rather than checking it, so input sanitization is partial.

