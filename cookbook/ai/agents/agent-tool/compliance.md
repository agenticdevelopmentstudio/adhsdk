
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | failed | reliability |

The contract types, the error type and the remote client are separate, and the transport and the host are injected or out of scope, so separation of concerns passes. Unit tests (the `RemoteAgentTools` suite) cover load, run, failure replies and a malformed list, but not a missing name, defaults for omitted fields, the event-stream reply, or the `AgentToolError` and `ToolPermission` types directly, so coverage is partial. Errors are thrown with typed cases and the host's message, and invalid argument JSON is refused with `invalidArguments` rather than sent (`remote-arguments-fallback`), but a missing or unknown `permission` is silently mapped to `auto` instead of being surfaced, so error handling is partial. The client sets no timeout and leaves it entirely to the transport, so timeout handling is failed.

