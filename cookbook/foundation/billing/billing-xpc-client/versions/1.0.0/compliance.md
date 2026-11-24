
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: the client only translates the service interface to transport calls and wire coding; rules are the daemon's and the transport is injected. unit-test-coverage is partial: `BillingXPCClientTests` covers the write bound and no-retry, stored values, refusal sentences, unreachable and unreadable, read-failed rows, negative counts, the preferences push and the reply decoder. No test covers a failing list read (vector 002), a zero count (vector 010), a successful delete, `billingOverview`, the entry filters, the 5-second preferences timeout or the default preferences push.

