
Pass-through

- **passthrough-connect**: `connect()` MUST call the wrapped transport's `connect()` and propagate its error.
- **passthrough-send**: `send(_:)` MUST write the data to the wrapped transport and propagate its error.
- **passthrough-receive**: `receive()` MUST return a stream that yields, in order, every message the wrapped transport's stream yields, finishes when the wrapped stream finishes, and finishes with the same error when it throws.
- **receive-stops-pump**: When the consumer of the returned stream terminates it, the task pumping the wrapped stream MUST be cancelled.
- **disconnect-releases**: `disconnect()` MUST disconnect the wrapped transport and then release every drain waiter, so nobody keeps waiting on a closed transport.
- **logger-silent**: The transport's logger MUST discard everything (a no-op handler).

Counting

- **count-request**: A message that is a JSON object with both an `id` and a `method` MUST be counted as a request owed a reply, as soon as it arrives and before it is yielded to the server, so the server cannot answer it before it is counted.
- **count-id-kinds**: A string id and a number id MUST be different ids: the string `"1"` and the number `1` MUST be recorded under different keys (`s:1` and `n:1`).
- **count-ignore-other**: A message that is not a JSON object, has no `method`, or has an `id` that is neither a string nor a number (null, object, array) MUST NOT be counted; a JSON boolean `id` is read as a number by the source (see Edge Cases). A batch (a JSON array) is not counted: the SDK answers a batch inside the receive loop, so its reply is sent before the loop ends.
- **count-notification-not-counted**: A message with a `method` and no `id` (a notification) MUST NOT be counted, except as described under cancellation.

Paying debts

- **pay-on-response**: When `send` writes a message that is a JSON object with no `method` and an `id` that is a string or a number, the matching owed id MUST be removed.
- **pay-after-send**: The debt MUST be paid after the wrapped `send` has been attempted, whether it returned or threw.
- **pay-on-cancel**: When a message arrives that has a `method` of `notifications/cancelled`, no `id`, and `params.requestId` that is a string or a number, the matching owed id MUST be removed, because the client has given up and MCP says the server need not answer a cancelled request.
- **pay-unknown-harmless**: Paying an id that is not owed MUST have no effect.
- **pay-releases-when-empty**: Whenever a payment leaves nothing owed, every drain waiter MUST be released.

Draining

- **owed-count**: `owedCount` MUST report the number of requests currently owed a reply.
- **wait-immediate-when-empty**: `waitUntilNothingOwed(deadline:)` MUST return true at once when nothing is owed.
- **wait-until-paid**: With something owed, `waitUntilNothingOwed(deadline:)` MUST suspend until nothing is owed or the deadline passes.
- **wait-deadline**: When the deadline passes first, all waiters MUST be released, and the call MUST return false because something is still owed.
- **wait-result**: The call MUST return whether nothing is owed at the moment it resumes, not whether it was released by the timer or by a payment.
- **wait-timer-cancelled**: The deadline timer MUST be cancelled when the call returns.
- **wait-multiple**: Several concurrent waiters MUST all be released by the same payment or the same deadline.

