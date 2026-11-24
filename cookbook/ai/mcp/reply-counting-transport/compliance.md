
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | Reliability |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |

`separation-of-concerns` passes: one small actor does one job, counting owed replies, and leaves serving, transport and the deadline policy to others. `timeout-configuration` and `timeout-handling` pass because the drain takes its deadline from the caller and always returns at it. `unit-test-coverage` passes: `HostMCPServerDrainTests` exercises the end-of-input drain, cancellation and the deadline, and `ReplyCountingTransportConformanceTests` drives a batch, a notification, string and number ids, a throwing wrapped `send`, an unknown cancelled id, `disconnect` with a waiter, and two waiters. `explicit-error-handling` is partial because unparseable messages are ignored silently and a throwing `send` pays the debt, both deliberate and recorded under Design Decisions.

