
Public surface

- **drain-deadline-value**: `stdioDrainDeadline` MUST be 360 seconds, long enough, per its comment, for a slow tool call such as temporal's mail sign-in, which waits up to 300 seconds for the browser plus an XPC timeout above that.
- **serve-stdio-transport**: `serveStdio()` MUST serve over a stdin and stdout transport using `stdioDrainDeadline`.
- **serve-stdio-returns**: `serveStdio()` MUST return only after input has closed and every request that arrived before that has been answered, or after the deadline has passed.
- **serve-stdio-throws**: `serveStdio()` MUST throw whatever error `serve(over:)` throws while starting.

Draining

- **drain-wraps-transport**: `serveUntilDrained(over:deadline:)` MUST wrap the given transport in a `ReplyCountingTransport` and serve over the wrapper.
- **drain-default-deadline**: The deadline parameter MUST default to `stdioDrainDeadline`.
- **drain-waits-for-loop**: After starting, the method MUST wait until the server's message loop ends, which happens when the transport's input ends.
- **drain-waits-for-replies**: After the loop ends, the method MUST wait until no request is owed a reply or until the deadline has passed, whichever is first.
- **drain-deadline-from-eof**: The deadline MUST count from the moment the wait begins, which is after the input has ended.
- **drain-stops-always**: The method MUST call `stop()` after the wait, whether or not every reply was written.
- **drain-warning**: When the deadline passes with replies still owed, the method MUST write one warning log line `MCP input closed; <n> request(s) unanswered at the deadline` with the count logged as public, and MUST then still stop.
- **drain-abandons**: A reply still missing at the deadline MUST be abandoned; it is not written.

Reply counting (`ReplyCountingTransport`)

- **counting-passthrough**: The wrapper MUST pass connect, disconnect, send and receive through to the wrapped transport unchanged, and MUST yield every received message to the server in order.
- **counting-request**: A received message with both an `id` and a `method` MUST be counted as owed as soon as it arrives, before the server sees it.
- **counting-response**: A sent message with an `id` and no `method` MUST pay the matching owed id.
- **counting-cancel**: A received `notifications/cancelled` whose `params.requestId` names an owed id MUST pay that id, because the client has given up and MCP lets the server skip a cancelled request.
- **counting-id-kind**: A string id and a number id MUST be different ids; the string `"1"` and the number `1` MUST NOT match each other.
- **counting-ignores-notifications**: A received message with a `method` and no `id`, other than a cancellation, MUST NOT be counted.
- **counting-batches**: A batch (a JSON array) MUST NOT be counted, because the SDK answers a batch inside its receive loop so the reply is written before the loop ends.
- **counting-unparseable**: A message that is not a JSON object MUST NOT be counted.
- **owed-count**: The wrapper MUST expose the number of owed ids as `owedCount`.
- **wait-nothing-owed**: `waitUntilNothingOwed(deadline:)` MUST return true at once when nothing is owed.
- **wait-releases-on-last-reply**: It MUST return true when the last owed id is paid before the deadline.
- **wait-deadline**: It MUST return false when the deadline passes first with ids still owed.
- **disconnect-releases-waiters**: `disconnect()` on the wrapper MUST release any waiter, so a drain does not outlive its transport.
- **input-end-passthrough**: The wrapper MUST finish its received stream when the wrapped stream finishes, and MUST finish it with the error when the wrapped stream throws.
- **stream-termination**: When the consumer ends the wrapper's received stream, the wrapper MUST cancel the task that reads the wrapped transport.

