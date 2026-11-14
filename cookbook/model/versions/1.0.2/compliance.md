
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Both statuses rest on the Localization section above: `titleCase` in
`lib/breadcrumbs.ts` and `lib/nav.ts` builds every label this module emits
directly from a URL segment, in English, with no string-table lookup or
externalization seam of any kind. `separation-of-concerns` passes because every
source file (`useSearchState.ts`, `breadcrumbs.ts`, `lookup.ts`, `nav.ts`,
`search.ts`) is pure logic with no rendering of its own, and `unit-test-coverage`
passes because each file has a matching direct test (`useSearchState.test.ts`,
`breadcrumbs.test.ts`, `lookup.test.ts`, `nav.test.ts`, `search.test.ts`) with
meaningful assertions.

