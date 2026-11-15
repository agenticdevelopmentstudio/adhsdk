
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |

`separation-of-concerns` passes because all three files perform no I/O,
storage, or transport of their own — per `no-persistence-no-side-effects`
above, they are only the data shapes shared between a chat backend, a tool
source, and the chat UI, each of which owns its own logic elsewhere.
`explicit-error-handling` passes because `ToolResult` represents a failed
tool call as an explicit `isError: Bool` field on returned data rather than
throwing, swallowing, or logging the failure silently — the same
explicit-outcome shape `ChatToolSource.callTool`'s return tuple already
uses.

`unit-test-coverage` fails because no Swift test references `ChatStreamEvent`, `ToolDefinition` or `ToolResult` under the Apple test targets; the web-side `adhChatBackend.test.ts` and `visitorChatSse.test.ts` exercise a different TypeScript event type, not these shapes.

