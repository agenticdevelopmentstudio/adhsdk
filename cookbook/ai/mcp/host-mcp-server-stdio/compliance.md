
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | reliability |

The drain logic sits in an extension and a transport wrapper, apart from routing in `HostMCPServer`. `HostMCPServerDrainTests` and `HostMCPServerStdioConformanceTests` cover every vector except host-mcp-server-stdio-015 (the drain warning line, skipped because the `Logger` cannot be captured in a unit test) and host-mcp-server-stdio-016 (`serveStdio()`, skipped because it reads the real process stdin and writes the real stdout). Coverage is therefore partial. The deadline bounds the wait and a missed reply is logged, so timeout handling passes. On a timeout the late replies are dropped with a warning, a degraded but surfaced result, so graceful degradation is partial.

