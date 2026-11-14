
- **Empty request bytes**: `timeout(for:)` MUST return `callTimeout` because empty bytes do not decode as a `MailRequest`.
- **Empty reply**: A zero-byte reply MUST become `<daemonName> dropped the reply`, not an empty successful result.
- **Reply that is not a valid response**: `send` MUST return the bytes without checking them; the decode failure arises later in `MailClient.send`, outside this type.
- **Failure after a deadline**: The transport does not enforce the 360 s deadline itself; it hands the value to `call`, and the host's IPC layer enforces it and reports expiry through `classify` as `timedOut`.
- **Long sync with healthy daemon**: `syncNow` MUST NOT be given a deadline, because it answers when the whole sync ends, joins a sync already running, and is paced at about 40 messages a second per the source comment.
- **Dead daemon during a sync**: With no deadline, the call ends through the dropped connection, which the host classifies as `connectionDropped`.
- **Empty daemon name**: Not validated; the name is interpolated as given into every sentence.
- **Empty or unusual `unreachable` detail**: Interpolated as given; an empty detail yields `cannot reach <daemonName>: `.
- **Cancellation**: No cancellation handling in the source; a `CancellationError` thrown by `call` goes through `onFailure` and `classify` like any other error, and the host's `classify` decides what it becomes.
- **Concurrent calls**: The transport holds no state, so concurrent `send` calls run independently; ordering and serialisation are the host's `call` closure's concern.
- **Offline or daemon not running**: Surfaces as `connectionDropped` or `unreachable` once classified, and then as the sentence above. There is no queueing and no retry.
- **Retry after failure**: Never. A repeated attempt is the caller's decision.

