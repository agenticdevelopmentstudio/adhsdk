
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |

separation-of-concerns passes: the type only parses, serialises and substitutes; where pairs are stored, and which streams are filtered, belong to its callers. unit-test-coverage passes: `AgenticDeveloperHubSDKCoreTests/TextSubstitutionFilterTests.swift` covers all twenty vectors, including empty-side dropping in `init(pairs:)`, duplicate patterns, literal metacharacters, Unicode text and `Pair` coding. explicit-error-handling is partial: parse errors are skipped by design, but a regular-expression compile failure is swallowed with `try?` and the input returned with no signal. input-sanitization passes: every pattern goes through `NSRegularExpression.escapedPattern(for:)` before it joins the expression. unicode-support passes: matching works over UTF-16 ranges with Unicode letter and number classes for whole words and case-insensitive matching.

