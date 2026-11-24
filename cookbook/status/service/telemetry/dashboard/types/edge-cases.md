
- **Null and empty values**: Nullable fields (`domain`, `p95Ms`, the vitals metrics, `shortId`, `release`, `permalink`, `firstSeen`, `lastSeen`, `summary.resolved`, `VercelRosterEntry.pageviews`) MUST be sent as `null` when unknown, never as 0 or an empty string. Null is not a zero.
- **Section never loaded or failed**: A section's `data` may be `null` while `error` is set or both are null; clients MUST handle a `null` `data` in every section.
- **Provider not configured**: Its sections are empty and its `configured` flag is false; clients MUST NOT treat that as a failure.
- **Partial answers**: `incomplete`, `failed`, `truncated`, `complete` and `resolved` null signal data that is short. A client MUST NOT present totals from a short answer as whole without saying so. These flags carry the information; the types do not hide it.
- **Row caps**: When `DimensionsSection.truncated` or `SiteErrorDetailSection.truncated` is true, the rarest rows are absent from every derived breakdown.
- **Session counts**: `TrafficSection.totals.sessions` counts a session twice if it spans two buckets, so it is not a deduplicated unique-visitor count.
- **Series length**: See `#requirements/series-length`: a hole is a zero.
- **Type drift between server and client**: The server and the web mirror can drift apart, because the mirror is hand-kept. The parity test catches it at type-check time only.
- **Concurrent access**: Not applicable: the file declares types and has no state; responses are built per request, and the cache beneath them is specified in the sectioned-dashboard recipe ([adhsdk.ingredient.status.service.telemetry.dashboard.sectioned-dashboard](cookbook:af0bacb9-bc1f-4773-85f5-35e33ae590ab)).
- **Error and offline states**: Not applicable here: the module does no I/O; a provider failure is carried in each section's `error` field, and the type has no separate failure envelope for the whole response.
- **Boundary values**: Not applicable: the types constrain no numeric ranges; the only enumerations are the range, dimension, breakdown and vital lists.

