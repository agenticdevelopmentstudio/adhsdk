
- **Empty reply**: Empty `Data` MUST be nil, because the daemon's "failed" and "did not apply" are empty data.
- **Garbage reply**: A body that is not a status MUST be nil, never a partial status.
- **Failed list read**: The failure row MUST make the whole read nil; a failed read is never "none".
- **Empty list**: An empty array MUST be an empty array, which the caller reads as no activity.
- **Slow Accessibility check**: A recheck, and a turn-on, MUST wait 15 seconds; a daemon that answers later makes both nil even though the daemon applied the change.
- **Timeouts on status and spans**: Both pass `timeout: nil`; the client passes `.none` and sets no wait of its own, so how long it waits is whatever the transport does for `.none`, which is outside this source and may be unbounded.
- **Body cannot be encoded**: `setPreferences` MUST return nil before any call is made.
- **Unreachable daemon**: The transport throws, the client returns nil, and the caller cannot tell it from a refusal or a bad reply.
- **Lost reply after a write**: A `setPreferences` that times out may still have been applied by the daemon; with no retry, the caller sees nil and may re-read `status()`.
- **Concurrent calls**: The client is a `final class` with only a `let` transport and no mutable state, so calls do not interfere; ordering of overlapping calls is the transport's and the daemon's.
- **Cancellation**: The calls are `async`, but the client adds no handling; whether a cancelled task abandons the XPC call is the transport's.
- **Offline**: Not applicable — XPC is local to the machine; an absent daemon is the unreachable case.

