
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.internationalization.plural-forms](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d24616b8-d1af-593d-ba01-f51ee4a91ea4) | partial | internationalization |

**Separation of concerns.** The module only formats text. Problem derivation and indicator state come from the server's board through `OverviewTab`, and the endpoint counts are computed by the caller.

**Unit test coverage.** No test file exists for `status-sublabel.ts`, and no other test in `status-web` exercises `buildSublabel`.

**Explicit error handling.** No operation can fail. Unknown status words and empty inputs have defined outputs (verbatim phrase and `""`), so nothing is silently dropped.

**No hardcoded strings.** Every phrase, and the separator, is an English literal in the source.

**Plural forms.** Five of the seven mapped phrases apply an English singular/plural switch on `n === 1`. `down`, `degraded` and unmapped words are never pluralized, and no locale plural rules are used.

