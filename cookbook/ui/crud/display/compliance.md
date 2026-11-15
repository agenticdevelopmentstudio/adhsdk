
| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | Internationalization |

`separation-of-concerns` passes because the function does one conversion and leaves
null, stringify and truncate formatting to its callers. `unit-test-coverage` passes: `display.test.ts` has one test per conformance
vector (display-001 to display-013), including the non-finite, wrong-type, wrong-name
and `RangeError` cases. `explicit-error-handling` is partial because
the out-of-range case throws without a guard or a documented message, though the
error is not swallowed. `locale-aware-formatting` is partial because the output is
a fixed UTC ISO string, deliberately matching the other timestamp columns, rather
than a locale-formatted date.

