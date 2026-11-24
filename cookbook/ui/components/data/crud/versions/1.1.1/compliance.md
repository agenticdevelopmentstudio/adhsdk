
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Status rests on `crud.tsx` hardcoding the literal English letters `"C"`, `"R"`, `"U"`, and `"D"` in `CRUD_LETTER` with no localization lookup; the source itself never renders these values, so whether a caller displays them to end users untranslated is outside what this file can confirm. `separation-of-concerns` passes because `crud.tsx` is a pure logic module — capability booleans, defaults, and the parent-clamping rule — with no rendering of any kind; `unit-test-coverage` passes because `crud.test.ts` directly exercises `CRUD_KEYS`/`CRUD_LETTER` agreement, `noAccess`, `readOnly`, and `clampToParent` with meaningful assertions.

