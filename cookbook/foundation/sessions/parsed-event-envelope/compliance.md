
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

separation-of-concerns passes: the extension only serializes one event and names the session, while parsing, spooling and quarantining are other types. unit-test-coverage is partial: `IngestSpoolTests` and `IngestDrainerTests` cover the round trip through the parser and the empty-type and session-less cases, but no test throws `notSerializable`, checks the key set, or pins the omitted-key rules for `context` and `oauth_account_email`. explicit-error-handling passes: an unserializable payload throws a typed error before any bytes exist and other encoder errors propagate. no-hardcoded-strings fails: the error description is an English literal with no localization table.

