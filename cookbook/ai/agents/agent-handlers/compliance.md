
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | access-patterns |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | access-patterns |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | passed | privacy-and-data |

The handlers keep routing, status mapping and serialisation apart from the host, registry and tools they call, which is the separation-of-concerns pass. Unit-test coverage is partial: the suites in `AgentHandlersTests.swift` exercise every route family, but several behaviors here have no test (extra path segments, array or empty bodies for tool calls, an unparseable tool schema, the `agent` filter for a missing agent, the `events` tail route and the model `models` route), so vectors 026 to 028 and every 029 to 043 vector marked "no test" are derived from source only. Error handling is explicit: every failure becomes a JSON reply with a code and message and `handle` never throws, the only silent projection being the tool-schema fallback documented above. The model routes keep secrets write-only and the tests assert that a posted secret does not appear in the reply.

