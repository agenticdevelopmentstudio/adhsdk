
### Poll interval

- **poll-filling**: The poll-interval function MUST return `5000` (milliseconds) when its argument is an object whose `refreshing` is true.
- **poll-settled**: The poll-interval function MUST return `60000` (milliseconds) when its argument's `refreshing` is false.
- **poll-no-data**: The poll-interval function MUST return `60000` when its argument is `undefined`, because no body has arrived yet to say the backend is refreshing.
- **poll-error-state**: Each read's interval MUST be `60000` while the read is in its error state (which, with the host cache's default retries, begins only once those retries are exhausted), even when the retained body says `refreshing`; the source's doc comment gives the reason: a failed read keeps the last body, and "a backend that has started failing would be polled every 5s for as long as it fails."
- **poll-after-recovery**: Each read's interval MUST return to being decided by the latest body's `refreshing` flag once a refetch succeeds and the read leaves the error state.
- **poll-interval-recomputed**: Each read MUST pass the interval as a function of the read's current state, so the interval changes after every settled fetch without the caller doing anything.

### The analytics-dashboard read

- **analytics-signature**: The analytics-dashboard read MUST accept a required `range` (an analytics range) and an optional second argument carrying an optional `enabled` boolean.
- **analytics-query-key**: The analytics-dashboard read MUST cache its result under a key combining `"analytics-dashboard"` and the `range`, so each range has its own cache entry.
- **analytics-request-path**: Each fetch MUST request the relative path `/analytics/dashboard?range=<range>`, which the client resolves against its base path (by default `/api`).
- **analytics-range-interpolation**: The `range` MUST be one of the three `AnalyticsRange` values (`"24h"`, `"7d"`, `"30d"`), which the type enforces; the source interpolates it into the query string by plain string conversion, with no percent-encoding and no runtime check, and the backend owns any further validation. A port MAY percent-encode the value.
- **analytics-keep-previous**: While a different range is loading, the analytics-dashboard read MUST keep returning the previous range's body as its data instead of dropping to an empty state; the source's comment says this is to "keep the last chart up while another range loads, instead of flashing skeletons."
- **analytics-focus-refetch**: The analytics-dashboard read MUST refetch when the window regains focus.

### The errors-dashboard read

- **errors-signature**: The errors-dashboard read MUST accept one optional argument, an options object carrying an optional `enabled` boolean.
- **errors-query-key**: The errors-dashboard read MUST cache its result under the single key `"errors-dashboard"`.
- **errors-request-path**: Each fetch MUST request the relative path `/errors/dashboard`, with no query string.
- **errors-no-placeholder**: The errors-dashboard read MUST NOT keep any previous body as placeholder data; it has no range to change.
- **errors-focus-refetch**: The errors-dashboard read MUST refetch when the window regains focus.

### Shared behavior of both reads

- **enabled-default**: Each read MUST fetch when `enabled` is omitted, `undefined` or `true`, and MUST NOT fetch when `enabled` is `false`.
- **return-value**: Each read MUST return the full read-result object unchanged (fields such as `data`, `error`, `isLoading`, `isError`, `isPlaceholderData`, `refetch`), adding no fields of its own.
- **client-source**: Each read MUST obtain its HTTP client through dependency injection, which resolves to the client supplied by the nearest override provider, or the same-origin default client (base path `/api`) when none is mounted.
- **request-init**: Each fetch SHOULD be issued through the client's raw request operation. The source passes no request options, so it is a default `GET` with no added headers, body or cancellation signal; a port MAY add an `Accept` header or cancel the request when its caller goes away.
- **success-body**: When the response is ok, the read MUST resolve with the parsed JSON body, typed as the response type without runtime schema validation.
- **non-ok-error**: When the response's `ok` flag is false, the read MUST throw an `Error` and enter its error state.
- **non-ok-message-detail**: The thrown error's message MUST be the message the response body carries when the body is JSON and yields a non-empty string: `error` when it is a string, otherwise `error.message`, otherwise `message`. A string `error` that is empty ends the search without trying `message`, and so does an `error.message` that is an empty string.
- **non-ok-message-fallback**: When the body yields no such message (not JSON, or none of the places above yields a non-empty string), the thrown error's message MUST be `status <code>` with the numeric HTTP status (for example `status 502`).
- **parse-failure**: When an ok response's body is not valid JSON, the rejection from parsing it MUST propagate as the read's error.
- **network-failure**: When the underlying request rejects (network failure or unreachable host), the rejection MUST propagate unchanged as the read's error.
- **stale-data-kept-on-error**: The reads MUST NOT clear the last good body when a refetch fails; the body stays in `data` beside the new `error`, which the poll-error-state rule relies on.
- **no-polling-when-disabled**: Each read MUST NOT poll while `enabled` is false, because the read is not fetching.
- **no-other-policy**: Each read MUST NOT set its own staleness duration, cache lifetime or retry count; those come from the host cache's defaults.
- **no-timeout**: Each read MUST NOT impose its own request timeout; a request that never settles leaves the read fetching until the client or browser ends it.
- **no-persistence**: Each read MUST NOT write dashboard data to any durable store; results live only in the in-memory shared cache.
- **shared-cache-entry**: Concurrent callers with the same key MUST share one cache entry; deduplicating their requests is done by the shared cache, not by this module, so two components calling the same read under one shared cache issue one request.
- **client-only**: This module MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

