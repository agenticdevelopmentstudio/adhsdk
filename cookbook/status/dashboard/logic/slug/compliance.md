
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | partial | Internationalization |

The function is a pure utility kept apart from the two editor components that call
it, so separation of concerns passes. Unit-test coverage fails because no `slug.test.ts`
sits beside `slug.ts`, while most sibling `lib` modules have one. Unicode support is
partial. The function takes any Unicode string without throwing and lower-cases it
with full Unicode rules. But it keeps only ASCII letters and digits, so accented,
non-Latin and emoji characters are dropped, and a wholly non-Latin name produces an
empty slug.

