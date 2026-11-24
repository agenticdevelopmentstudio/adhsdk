
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |

`separation-of-concerns` passes because rendering (`JsonLd`), graph assembly (`withWebSite`) and normalizing (`graphOf`, private) are three small functions with no I/O. `unit-test-coverage` passes: `json-ld.test.tsx` has one test for each of vectors 001 to 013, and `agent.test.tsx` also covers the added WebSite, the kept WebSite and the `<` escape. `input-sanitization` passes because the one input that can end the element, `<`, is escaped and tested. `explicit-error-handling` is partial because serialization failures surface as an uncaught exception at render time with no handling.

