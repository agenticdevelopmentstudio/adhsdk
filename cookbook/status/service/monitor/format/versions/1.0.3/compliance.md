
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |

`unit-test-coverage` is `partial`: `format.test.ts` gives `commitFullMessage` full
assertion coverage across empty input, newline preservation, trailing-whitespace
stripping, and the `max` cap, but the given source tree contains no dedicated test file
exercising `shortSha` or `commitFirstLine` at all — their behavior in this recipe is
derived from reading `format.ts` directly, not from a passing assertion. `separation-of-
concerns` passes: this file owns exactly one concern, commit-display formatting, and its
own header comment frames its reason for existing as removing that concern from the
fetchers and row builders that used to duplicate it. `explicit-error-handling` passes:
none of the three functions has an error path to swallow — there is no exception handling
and no I/O that could fail — and the `null` each returns for absent or empty input is a
deliberate, documented sentinel value (per the requirements above), not a caught or ignored
failure.

