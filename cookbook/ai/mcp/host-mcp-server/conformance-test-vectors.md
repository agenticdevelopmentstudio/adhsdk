
Derived from `HostMCPServerTests` where named; the rest are traced to the source. "Pair" means a server and client joined by an in-memory transport.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| host-mcp-server-001 | list-concatenates | Sources with names a, b and c; `tools/list` (`testListToolsConcatenatesSourcesInRegistrationOrder`) | Names `a`, `b`, `c`; first description `echo a` |
| host-mcp-server-002 | list-schema, list-description | One source whose schema has a string property `x`; `tools/list` (`testInputSchemaIsTheDefinitionsSchema`) | Schema type is `object` and `properties` contains `x` |
| host-mcp-server-003 | call-routing, call-arguments-json, call-first-match-only | Two sources (`a`, `b`); call `b` with `x` set to `1` (`testCallRoutesToTheSourceThatAdvertisesTheName`) | Text `echo:b`, no error; second source received arguments `{"x":"1"}`; first source received no call |
| host-mcp-server-004 | call-result-error-flag, call-result-text | Source whose tool `fails` returns `it failed` with error true (`testErrorResultIsErrorWithTheSentence`) | `isError` true, text `it failed` |
| host-mcp-server-005 | call-unknown-tool | Call `nope` with no matching source (`testUnknownToolIsAnErrorResultNotAProtocolError`) | Result `isError` true, text `unknown tool nope`, no protocol error |
| host-mcp-server-006 | list-prefix, call-prefix-stripped | Source `info` registered with prefix `host_`; list, then call `host_info` (`testPrefixIsAppliedToNamesAndStrippedOnCall`) | Listed name `host_info`; source received name `info` |
| host-mcp-server-007 | call-result-image | Source returns `data:image/png;base64,iVBORw0KGgo=` (`testPNGDataURLBecomesImageContent`) | One image item, MIME `image/png`, data `iVBORw0KGgo=` |
| host-mcp-server-008 | serve-stops-previous, fresh-server-per-serve | Serve over a first pair and connect, then serve over a second pair and connect a new client (`testSecondServeStopsTheFirst`) | The second client initializes without error and lists `a` |
| host-mcp-server-009 | call-caller, caller-header-case | Request with header `x-adkitchen-pane: pane-7`; read caller, call the server with it (`testCallerHeaderReachesTheSource`) | Caller `pane-7`; the source records caller `pane-7` |
| host-mcp-server-010 | call-caller | No request, or a request with no header | Caller is nil |
| host-mcp-server-011 | caller-header-name | Read `HostMCPServer.callerHeader`, `legacyCallerHeader` and `callerHeaders` | `X-ADHD-Pane`; `X-ADKitchen-Pane`; both, the new name first |
| host-mcp-server-012 | list-schema-fallback | Source whose definition's schema bytes are not JSON; `tools/list` | The tool is listed with schema type `object` and empty properties |
| host-mcp-server-013 | call-arguments-json | Call with no arguments | Source receives `{}` |
| host-mcp-server-014 | call-image-error-flag | Source returns the PNG data URL with the error flag true | Image content with `isError` true |
| host-mcp-server-015 | list-duplicates-kept | Two sources both advertising `a`; `tools/list` | Two entries named `a`; a call goes to the first source |
| host-mcp-server-016 | registrations-survive-stop | Register a source, serve, stop, serve again over a new transport | The second connection lists the same tools without re-registering |
| host-mcp-server-017 | stop-clears-server | Call `stop()` on a server that never served | Returns with no effect and no error |
| host-mcp-server-018 | tools-capability, not-strict | A client calls `tools/call` over a stateless transport with no prior `initialize` | The call is answered, not refused |
| host-mcp-server-019 | register-appends, prefix-default | Register two sources with no prefix | Both are listed in the order registered |
| host-mcp-server-020 | construction-parameters | Construct with app name `Test` and version `1`, connect a client | The client's initialize result names server `Test` version `1` |
| host-mcp-server-021 | serve-throws-start-failure | Transport whose connect throws | `serve(over:)` throws and a following `stop()` does nothing |
| host-mcp-server-022 | call-log | One successful, one failing and one unknown call | Info lines `tools/call a ok`, `tools/call fails error`, `tools/call nope unknown` |
| host-mcp-server-023 | list-asks-sources-live, call-asks-definitions | Source whose definitions change between two `tools/list` requests | The second listing reflects the change |
| host-mcp-server-024 | call-result-text | Source returns `hello` | One text item `hello`, no image |
| host-mcp-server-025 | list-server-gone, call-server-gone, wait-until-completed | Server deallocated before a request; and `waitUntilServerCompleted()` with no server | Empty list and `server is gone`; the wait returns at once. `HostMCPServerConformanceTests` reaches both: it drops the server after serving, then lists and calls, and it waits on a server that never served. |

