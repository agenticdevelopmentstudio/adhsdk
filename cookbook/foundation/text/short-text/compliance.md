
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |

separation-of-concerns passes: the extension only shortens a string; where the budget comes from and how the result is shown belong to its callers. unit-test-coverage is partial: `ShortTextTests` covers under the limit, exactly the limit and over the limit with the result length, but nothing asserts the default of 60, a limit of 3, an empty string, or a multi-scalar character. unicode-support passes: the length and the cut are counted in `Character`s so a grapheme cluster is never split.

