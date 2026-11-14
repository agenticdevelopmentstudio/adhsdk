
- **Empty body**: an ok response whose body is `{}` or `null` MUST be returned as the read's `data` unchanged; the module performs no shape check, so `refreshing` is read from whatever arrived and a body with no `refreshing` makes the poll interval `60000`.
- **Boundary — range value**: a `range` outside `"24h"`, `"7d"`, `"30d"` MUST be sent as given and any error response MUST surface through the non-ok path; the backend's own message (for example `invalid range`) is what the error carries.
- **Boundary — enabled toggling**: switching `enabled` from `false` to `true` MUST start the fetch and the polling; switching it back to `false` MUST stop both, while the cached body stays in the shared cache.
- **Error states — failure while refreshing**: a refetch failure after a body marked `refreshing` MUST drop the interval to 60 seconds and keep the old body; once a later fetch succeeds the interval follows the new body.
- **Error states — unreadable error body**: when the non-ok body is not JSON, the module MUST still throw, with the `status <code>` message.
- **Offline or disconnected state**: a request that rejects because the network is down MUST surface as the read's error with the transport's own message and MUST be polled again 60 seconds later, plus on window focus; the module has no offline detection and no backoff of its own.
- **Concurrent access**: two callers with the same key share one cache entry and one in-flight request through the shared cache; callers with different ranges hold separate entries and poll independently. The module holds no state of its own, and JavaScript is single-threaded, so no ordering rule is needed here.
- **Cancellation and timeouts**: the module passes no abort signal and sets no timeout; an unmounted caller does not cancel an in-flight request through this module.
- **Placeholder across ranges**: while a new range is loading the previous range's body is shown, so a view MUST check the read's placeholder flag if it needs to tell the two ranges apart; the module offers no other signal.
- **Background tab**: the interval is a poll setting handed to the shared cache; whether it keeps firing while the tab is hidden is that library's default, not something this module sets.

