
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The session separates concerns well: it owns no process, no persistence and no view, and takes its outbound behavior as closures. `unit-test-coverage` is partial: `AgenticDeveloperHubSDKCoreTests/Partner/PartnerChatSessionTests.swift` covers vectors 001 to 021 and 023 to 025, and skips vector 022, which needs a Thread Sanitizer run that a unit test cannot detect. A failed turn is surfaced as `.turnFailed`, so error handling is explicit. The fallback strings `tool` and `error` are hardcoded English that can reach the UI, which fails the hardcoded-strings check.

