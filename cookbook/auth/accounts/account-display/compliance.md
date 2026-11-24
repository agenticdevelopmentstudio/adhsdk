
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes because the type holds only visibility rules: it draws nothing, stores nothing and performs no I/O, and leaves rendering to each platform's views. `unit-test-coverage` passes: `AccountDisplayTests` (`Accounts/AccountDisplayTests.swift`) asserts all fourteen vectors, including the `@MainActor` account-based initializer, the `restoringText` value and an empty-string message. `no-hardcoded-strings` fails because `restoringText` is an English literal with no localization lookup.

