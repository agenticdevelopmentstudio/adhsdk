
- **Input closes before any request**: nothing is owed, so the method MUST stop at once.
- **Input closes with several requests in flight**: every reply MUST be written if each finishes before the deadline.
- **A reply never comes**: the method MUST give up at the deadline, log the warning with the count and stop; the reply is lost.
- **Cancelled request**: MUST NOT hold the drain open; covered by `testACancelledRequestIsNoLongerOwedAReply`.
- **Cancellation of an id that is not owed**: MUST have no effect.
- **Duplicate request ids**: the owed set holds each id once, so a second request with the same id, and then one reply, leaves nothing owed.
- **Batch request**: not counted; the reply is written inside the receive loop, so a batch is answered before the loop ends.
- **Malformed message**: not counted and still passed to the server, which decides what to do.
- **Transport throws while reading**: the error ends the wrapper's stream, the server's loop ends, and the drain proceeds to its wait and stop.
- **Start fails**: `serve(over:)` throws, the error propagates, and the wait and stop are skipped.
- **Concurrent access**: `ReplyCountingTransport` is an actor, so its owed set and waiter list are serialised; any number of waiters may wait at once and all are released together.
- **Offline or disconnected state**: standard input and output are local pipes; a peer that disconnects looks like end of input and follows the normal drain path.
- **Slow tool call**: a tool call that takes longer than 360 seconds after input closes is abandoned at the deadline.

