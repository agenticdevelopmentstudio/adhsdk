
- **Null and empty input, empty collection**: MUST return `[]` from `listAllV1` when the first page has empty `data`, whatever `has_more` says (stop-on-empty-page).
- **Null and empty input, missing body**: MUST treat a null or undefined parsed body as an empty page with no more rows; `authedJson` itself throws on a 204 response before this module sees it.
- **Null and empty input, query params**: MUST ignore `null` and `undefined` param values and MUST remove a key given an empty array (query-drop-nullish, query-empty-array). An empty `params` object returns `url` with its existing keys and values, re-serialized through `URLSearchParams` (so a `%20` in an existing value comes back as `+`).
- **Malformed input, bad page shape**: MUST fall back to an empty `data` array when the server sends a non-array `data`; the module does not report the malformation.
- **Malformed input, bad timestamp**: `isoToUnix` returns `NaN` for an unparseable string and `unixToIso` returns `null` for a non-finite number; a caller that persists the result MUST check for both.
- **Boundary values, page size**: MUST always request `limit=100`; a caller-supplied `limit` in `url` is overwritten. `listV1Page` sends no `limit`, so the page size is whatever `url` carries or the server defaults.
- **Boundary values, timestamps**: `unixToIso` accepts negative seconds (pre-1970) and fractional seconds; the result carries millisecond precision. `isoToUnix` floors, so a fractional second is lost and a pre-1970 instant rounds toward earlier time.
- **Boundary values, cursor types**: A numeric `id` is accepted as a cursor and stringified; an `id` of `null`, an object or a boolean yields no cursor.
- **Error states, truncation**: MUST throw rather than return a partial list when `has_more` is true and the last row has no cursor (truncation-guard).
- **Error states, HTTP failure**: MUST propagate the `authedJson` error (an `AuthHttpError` carrying status, code and body, or a network error) and discard partially collected rows. The module adds no retry beyond the one refresh-and-retry inside `authedJson`.
- **Error states, runaway server**: The module has no page cap or repeated-cursor detection, so a server that never clears `has_more` while changing nothing keeps the loop requesting (no-loop-guard). This is the module's behavior; the gateway owns the correctness of `has_more`.
- **Concurrent access**: Not applicable to shared state, because the module holds none; two concurrent `listAllV1` calls each walk their own cursor. A collection mutated between page requests can yield a row twice or skip one, which the cursor design does not prevent; the `/v1` gateway owns that guarantee.
- **Offline or disconnected state**: A request that fails because the network is down rejects with the fetch error and aborts the walk (error-propagation); there is no queueing, caching or resume.
- **Cancellation and timeout**: Neither is supported; `init.signal` is passed through to each page request, so a caller MAY abort by supplying an `AbortSignal`.
- **Request method**: `init` is passed through without forcing GET, so an `init` carrying another method or a body is sent as given on every page.

