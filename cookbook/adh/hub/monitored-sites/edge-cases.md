
- **Null and empty input — `workspace`**: not checked client-side in any of the twelve operations. The
  `workspace` option is optional and may be absent; an empty string is silently omitted from the
  query, since the shared scoping helper only passes a truthy `workspace` through. This is a MUST per the observed source; no validation exists.
- **Null and empty input — required create fields**: the create-group, create-site, and create-endpoint
  operations perform no client-side check that `name`/`slug`/`url` are non-empty; an empty string is
  sent to the backend unchanged, since the body-compaction helper only drops absent values, never an
  empty string. MUST behave this way per source.
- **Boundary values — `retentionDays`/`expectedStatus`/`checkIntervalSeconds`**: none of these numeric
  fields has a client-side minimum, maximum, or integer check; whatever number the caller supplies
  (including negative, zero, or non-integer) is sent to the backend unchanged. MUST behave this way per
  source — no declared closed set constrains these fields, unlike `kind`.
- **Boundary values — large collections**: the list-groups, list-sites, and list-endpoints operations
  accept no pagination, cursor, or limit parameter from the caller; the shared paging helper fetches
  `limit=100` pages, advancing `starting_after` while the response reports `has_more`, so a workspace
  with more than one page of groups, sites, or endpoints still receives the complete list, at the cost
  of one request per page. A page that reports `has_more` but whose last row has no id throws rather
  than looping.
- **Concurrent access — module state**: this module holds no shared mutable state between calls (only
  the three read-only path constants and the fixed set of valid endpoint kinds), so there is nothing for
  two concurrent calls to race on within the module itself.
- **Concurrent access — competing writes**: two concurrent update-site/update-group/update-endpoint calls
  for the same `id` follow ordinary last-write-wins `POST` update semantics — last response received wins, with no client-side
  sequencing, optimistic-lock check, or `updatedAt`-based conflict detection in this recipe.
- **Concurrent access — reparent then list**: calling the update-site operation to move a site to a new
  group and then immediately calling the list-sites/list-endpoints operations issues independent
  requests with no client-side cache to invalidate; the second request's freshness depends entirely on
  the backend having committed the first, which this module does not wait on beyond the first request's
  own response.
- **Error states — non-2xx response**: every non-`401` failure and every unresolved `401` throws a
  typed HTTP error carrying the HTTP status and optional code (`errors-carry-status-and-code`); nothing
  in this recipe catches or swallows that error.
- **Error states — `204` on a declared-void write**: the delete-group, delete-site, and delete-endpoint
  operations discard the response body and do not special-case `204`, so a `204` response resolves
  normally; this differs from operations that decode a JSON body, which treat `204` as an error — none
  of the create or update operations can receive a bodiless `204`, since decoding a response treats that
  as an error regardless of caller intent.
- **Offline or disconnected state**: none of the twelve operations catches a network-level connection
  failure; a connectivity loss mid-call propagates as an unhandled asynchronous rejection out of this
  module to the caller, with no retry, queuing, or offline-specific handling anywhere in this recipe.
- **No timeout**: no operation sets a deadline or cancellation signal; a reachable-but-unresponsive
  backend leaves the call pending until the underlying transport's own limit, if any.
- **No cancellation**: no operation accepts a cancellation-signal parameter, so a caller cannot cancel
  an in-flight request through this module.
- **No retry beyond the `401` waterfall**: every write issues exactly one request and every list one request per page (plus, on a `401`, the
  single inherited refresh-and-retry); nothing in this recipe retries a network failure or a non-`401`
  error status.
- **Stale module doc comment**: this module's own top-of-file comment states "the client-side narrowing
  in listSites()/listEndpoints() stays as defense-in-depth," but the list-sites operation's
  implementation performs no such filter — it maps and sorts the response with no owner/workspace
  narrowing of its own; only the list-endpoints operation retains a client-side filter (on `siteId`, per
  `endpoint-list-double-filtered`), and there it is the only site narrowing, not defense-in-depth. This is recorded as an observed discrepancy between the source's
  comment and its code in Design Decisions, not smoothed over.

