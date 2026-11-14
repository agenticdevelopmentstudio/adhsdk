
**Decision**: `messages()` is single-consumer and later calls get a finished stream.
**Rationale**: The stream wraps one stdout reader; two consumers would split the messages between them, so the second call is made harmless instead.
**Approved**: pending

**Decision**: An undecodable stdout line is skipped and logged at debug level.
**Rationale**: A stray non-JSON line, such as a warning, should not end the conversation; the cost is that a malformed message is silent apart from the debug log.
**Approved**: pending

**Decision**: The pump is detached and captures no actor state.
**Rationale**: The process must not be kept alive by its own reader, and decoding stays off the actor so a slow decode does not block `send` or `terminate`.
**Approved**: pending

**Decision**: The caller's environment is applied with the replace policy.
**Rationale**: The caller hands over the child's whole environment, so a variable it removed stays removed rather than being re-inherited; this is the replace policy of the channel the process runs over.
**Approved**: pending

**Decision**: A stdout read error finishes the stream rather than throwing from it.
**Rationale**: The `AsyncStream` type has no error channel; the consumer learns the cause from `standardErrorText()` and `isRunning`. The alternatives weighed are an `AsyncThrowingStream`, which would carry the error but make every consumer handle a throw, and a terminal `ended(reason)` message value, which would carry the reason in-band but change the message type; neither was chosen, so this decision stays pending.
**Approved**: pending

