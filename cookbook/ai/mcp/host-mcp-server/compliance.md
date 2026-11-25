
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | security |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | failed | access-patterns |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | failed | security |

Separation of concerns is partial because `AgentToolSource` shares this ingredient (see its Design Decision). Server-side authorization fails for the bridge: it runs mutating and ask-permission tools with no permission check, an accepted risk with a removal trigger recorded in Design Decisions. The server keeps routing, the MCP translation and transport choice separate: transports and tool sources arrive from outside. `AgentToolSourceTests` cover vectors 026 to 034. `HostMCPServerTests` and `HostMCPServerConformanceTests` cover every server vector except host-mcp-server-022 (the call log lines), which is skipped because the `Logger` is a private OSLog instance with no injection point; overlapping serve calls are an unspecified edge case with a pending Design Decision. Coverage is therefore partial. Failures come back as error results. Logs carry tool names and outcomes only, not arguments or results. The server sets no timeout on a source call, so a hung source holds its request open; the transport owner or the stdio drain deadline bounds it.

