
- **Empty reply data**: For the three status calls, empty `Data` MUST mean the call failed or did not apply; a zero-byte body is never a valid status.
- **Undecodable reply**: A body that is not a valid status is not distinguished by the protocol; the client treats it like empty data (client behavior, see [adhsdk.ingredient.foundation.work-tracking.work-tracking-xpc-client](cookbook:f3f1af27-6cd7-4b3f-9024-135c6f6e89da)).
- **Sentinel among rows**: The failure row is declared as the single element of a failed read; a client seeing it anywhere in the array treats the read as failed (client behavior, see [adhsdk.ingredient.foundation.work-tracking.work-tracking-xpc-client](cookbook:f3f1af27-6cd7-4b3f-9024-135c6f6e89da)).
- **Empty list**: An empty array MUST mean no activity, never a failure.
- **Slow recheck and slow turn-on**: A recheck, and a set-preferences that turns tracking on, are answered only after the daemon's live Accessibility check, which the doc comment on `recheckTimeout` in `WorkTrackingXPCClient.swift` says stalls about ten seconds without the grant; the protocol states no deadline, and the client owns the timeouts ([adhsdk.ingredient.foundation.work-tracking.work-tracking-xpc-client](cookbook:f3f1af27-6cd7-4b3f-9024-135c6f6e89da)).
- **Daemon unreachable or interrupted**: Not expressible in the protocol; the transport call throws, and the client answers nil for it, as it does for empty data ([adhsdk.ingredient.foundation.work-tracking.work-tracking-xpc-client](cookbook:f3f1af27-6cd7-4b3f-9024-135c6f6e89da)).
- **Selector drift**: Renaming a selector would make the call fail at runtime with no compile error on the daemon side, so the names are fixed.
- **Concurrent access**: The protocol declares no ordering; NSXPC delivers calls on the daemon's connection queue, and serialization is the daemon's.
- **Cancellation, offline**: Not applicable — the protocol declares no cancellation, and XPC is local to the machine.

