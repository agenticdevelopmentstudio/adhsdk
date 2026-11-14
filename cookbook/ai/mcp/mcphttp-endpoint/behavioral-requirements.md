
Constants and construction

- **path-constant**: `MCPHTTPEndpoint.path` MUST be `/mcp`.
- **preferred-port-constant**: `MCPHTTPEndpoint.preferredPort` MUST be `51477`.
- **timeout-constant**: `MCPHTTPEndpoint.requestTimeout` MUST be 120 seconds, because a navigation or wait tool can legitimately run for a while; FlyingFox's default is 15 seconds.
- **init-parameters**: The initializer MUST take the server, the bearer token, an optional preferred port (default `preferredPort`), an optional request timeout (default `requestTimeout`) and an optional logger (default subsystem `AgenticDeveloperHubSDK`, category `automation`). Construction MUST NOT bind anything.

Starting and stopping

- **start-returns-bound-port**: `start()` MUST bind `127.0.0.1` on the preferred port and return the port actually listening.
- **start-loopback-only**: The listening address MUST be `127.0.0.1`, never a wildcard or external address.
- **start-falls-back-to-ephemeral**: When binding the preferred port fails and the preferred port is not 0 and no stop was requested, `start()` MUST log that the port is taken and bind port 0, then return the ephemeral port the system gave.
- **start-idempotent-when-running**: `start()` called while running MUST return the port it is already on without binding again.
- **start-serves-before-listening**: `start()` MUST first call `server.serve(over:)` with a fresh stateless transport, and only then bind the socket, so the first request already finds a served server.
- **start-while-starting-or-stopping**: `start()` called while another `start()` is binding, or while a `stop()` is tearing down, MUST throw `StartError.alreadyStarting`.
- **start-bind-confirmation**: `start()` MUST treat the bind as failed when the HTTP server's run loop ends early or does not report listening within 5 seconds, and MUST read the bound port from the listening address (IPv4 or IPv6); any other address kind, or no address, MUST fail with a file-not-found Cocoa error.
- **start-failure-cleans-up**: When `start()` throws for any reason, it MUST tear down everything it built (listener, run task, transport, port, server), return to idle, clear the stop request, and rethrow.
- **stop-tears-down**: `stop()` MUST stop the listener with a 1 second timeout, cancel the run task, clear the port and transport, and stop the `HostMCPServer`, then leave the endpoint idle and restartable.
- **stop-while-starting**: `stop()` called while `start()` is binding MUST record the request and return at once; `start()` then tears down what it built and throws `StartError.stoppedWhileStarting`.
- **stop-idempotent**: `stop()` called while already stopping, or while idle, MUST NOT fail; while stopping it returns at once.
- **stop-hides-closing-port**: `stop()` MUST flip the phase to stopping and move the listener, task, transport and port out of the actor's state before its first suspension, so a `start()` arriving meanwhile can neither see the closing port nor bind a second server.
- **port-observable**: The `port` property MUST be the bound port while running and nil otherwise.

Authorization

- **auth-bearer-required**: Every `POST /mcp` request MUST carry `Authorization: Bearer <token>` equal to the configured token; any other value, or no header, MUST be answered 401 with the response header `WWW-Authenticate: Bearer`.
- **auth-constant-time**: The token comparison MUST combine the length difference and every byte difference into one accumulator and MUST NOT return early on the first differing byte.
- **auth-before-body**: Authorization MUST be checked before the body is read or parsed.

Routing

- **route-post-only**: Only `POST /mcp` MUST reach the MCP transport.
- **route-wrong-method-405**: A request to `/mcp` with any other method MUST be answered 405 with the header `Allow: POST`.
- **route-wrong-path-404**: A request to any other path MUST be answered 404.

Id rewriting

- **rewrite-single-object-with-id**: A request body that is a single JSON object whose `id` is a string or an integer MUST be forwarded with its `id` replaced by a fresh UUID string, and the original id MUST be remembered.
- **rewrite-passthrough**: A body that is an array, has no `id`, has a null, boolean or fractional `id`, or cannot be parsed or re-serialised MUST be forwarded unchanged. A null id is no id to the SDK (a notification), so the endpoint MUST NOT turn it into a request.
- **rewrite-restore-response**: In the response body, when it is a JSON object whose `id` equals the unique id, the endpoint MUST put the caller's original id back, preserving its type (integer stays integer, string stays string). Any other response body MUST pass through unchanged.

Caller identity

- **caller-header-forwarded**: The endpoint MUST forward every request header to the transport so the server can read the caller header (`HostMCPServer.callerHeader`, `X-ADKitchen-Pane`) and give the tool source the caller id; a request without it reaches the source with no caller.

Cancellation

- **cancel-recognise**: A body MUST be treated as a cancellation when it is a JSON object with no rewritable id, whose `method` is the MCP cancelled-notification name (`notifications/cancelled`), and whose `params.requestId` is a string or an integer.
- **cancel-keyed-by-caller**: The endpoint MUST track in-flight requests by the pair (caller header value or empty, the id the caller sent) so a cancellation from one caller cannot stop another caller's request that happens to use the same id.
- **cancel-translate**: For a recognised cancellation whose key is in flight, the endpoint MUST forward the notification with `params.requestId` replaced by the unique id, then release the waiting request (see `cancel-release`).
- **cancel-unknown-passes**: For a cancellation whose key is not in flight (already answered, or another caller's), the endpoint MUST forward it unchanged and the SDK ignores it; the HTTP answer to the notification itself MUST be the transport's (202 with no body).
- **cancel-release**: Releasing a cancelled request MUST send the transport a JSON-RPC error response for the unique id with code `-32800` and message `request cancelled: <reason>`, so the HTTP call waiting on it is answered rather than held open until the timeout. A release arriving after a real response finds no waiter and the transport drops it.
- **cancel-timeout-forwarded**: When FlyingFox's request timeout cancels a handler, the endpoint MUST send the transport a `notifications/cancelled` for the unique id with reason `the HTTP request timed out`, and then release it, so the tool call stops and the client is answered.
- **inflight-reuse-last-wins**: When a caller reuses an id while the first request is still in flight, the later request's unique id MUST win the key; the earlier request's completion MUST NOT forget the later entry.
- **inflight-cleared-on-completion**: A request's in-flight entry MUST be removed when its handler returns.

Response mapping

- **response-status-map**: The SDK's status code MUST be mapped to the matching FlyingFox status for 200, 202, 400, 401, 403, 404, 405, 406, 421 and 500, and to a status with that numeric code and an empty phrase otherwise.
- **response-headers-copied**: The SDK response's headers MUST be copied onto the FlyingFox response.
- **response-stream-collected**: A streamed SDK response MUST be collected into one body. A stream that fails midway MUST become an empty 500, never a truncated 200.

Logging

- **log-outcomes**: The endpoint MUST log each handled request's path and status, each 401, each cancellation, the port-taken fallback, and the listening port, none of which includes the token or body.

