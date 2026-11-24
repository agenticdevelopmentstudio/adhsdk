
Derived from `HostMCPServerDrainTests` where named; the rest are traced to the source. The scripted transport used by the tests yields a fixed list of messages and ends at once, as piped standard input does.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| host-mcp-server-stdio-001 | drain-waits-for-replies, drain-stops-always | Script: `initialize` (id 1), `notifications/initialized`, `tools/list` (id 2); a source whose definitions take 300 ms; `serveUntilDrained(over:)` (`testRequestsInFlightWhenInputClosesAreStillAnswered`) | Responses for ids 1 and 2 are both sent before the method returns |
| host-mcp-server-stdio-002 | counting-cancel, owed-count, wait-releases-on-last-reply | Script: `tools/call` id 5, `tools/list` id `"6"`, `notifications/cancelled` for 5; read to the end (`testACancelledRequestIsNoLongerOwedAReply`) | `owedCount` is 1 |
| host-mcp-server-stdio-003 | counting-response, wait-releases-on-last-reply, counting-id-kind | Then send the response with id `"6"` and wait with a 30 s deadline (`testACancelledRequestIsNoLongerOwedAReply`) | The wait returns true in under 5 s |
| host-mcp-server-stdio-004 | drain-deadline-from-eof, drain-abandons, drain-warning, wait-deadline | Same script; a source whose definitions take 60 s; deadline 300 ms (`testDrainGivesUpAtItsDeadline`) | The method returns in under 10 s; only the response for id 1 was sent |
| host-mcp-server-stdio-005 | counting-id-kind | Receive a request with number id 1 and send a response with string id `"1"` | `owedCount` stays 1 |
| host-mcp-server-stdio-006 | counting-ignores-notifications | Receive `notifications/initialized` | `owedCount` is 0 |
| host-mcp-server-stdio-007 | counting-batches | Receive a JSON array of two requests | `owedCount` is 0 |
| host-mcp-server-stdio-008 | wait-nothing-owed | Wait with nothing owed and a 30 s deadline | Returns true at once |
| host-mcp-server-stdio-009 | counting-unparseable | Receive the bytes `not json` | `owedCount` is 0 and the bytes are still yielded |
| host-mcp-server-stdio-010 | drain-deadline-value | Read `HostMCPServer.stdioDrainDeadline` | 360 seconds |
| host-mcp-server-stdio-011 | counting-passthrough | Send bytes through the wrapper | The wrapped transport receives the same bytes |
| host-mcp-server-stdio-012 | disconnect-releases-waiters | One request owed, a waiter pending, then `disconnect()` | The waiter returns false |
| host-mcp-server-stdio-013 | input-end-passthrough | Wrapped stream throws an error | The wrapper's stream ends with that error |
| host-mcp-server-stdio-014 | serve-stdio-throws | Transport whose connect throws, via `serveUntilDrained(over:)` | The method throws that error |
| host-mcp-server-stdio-015 | drain-warning | Same as 004 with the logs captured | One warning `MCP input closed; 1 request(s) unanswered at the deadline` |
| host-mcp-server-stdio-016 | drain-wraps-transport, drain-default-deadline, serve-stdio-transport, serve-stdio-returns, drain-waits-for-loop | `serveStdio()` with stdin piped one `tools/list` request | The reply is written to stdout before the method returns. The source gives no test; this is asserted from the source comments and the `temporal mcp` example. |
| host-mcp-server-stdio-017 | counting-request, owed-count, stream-termination | Receive a request, then end the consumer's stream early | The reader task is cancelled; `owedCount` is 1 |

