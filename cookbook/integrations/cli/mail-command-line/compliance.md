
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

`MailCommandLine` keeps parsing and formatting apart from the transport by taking an injected `MailClient` and output closures, so separation-of-concerns passes. `MailCommandLineTests` asserts every command, every usage-error path, the exit statuses and the text and JSON forms, so unit-test-coverage passes. Every thrown error is mapped to a status and a message on `stderr`, so explicit-error-handling passes. Input sanitization is partial: limits, dates and blank queries are validated, but account names, label names and ids are forwarded unmodified for the client and service to validate. No-hardcoded-strings fails because every user-facing string is English text in the source, with no externalization; this is a deliberate property of a developer command line, recorded under Localization.

