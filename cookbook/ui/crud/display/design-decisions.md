
**Decision**: Only the two columns named `created` and `updated` are converted, and only when the descriptor type is `integer` and the value is a number.
**Rationale**: The `/v1` API serves exactly those two timestamps as integer unix seconds while every other timestamp column stays an ISO string, so a wider rule would risk rewriting ordinary integer columns such as counts. The source comment states this directly.
**Approved**: pending

**Decision**: A value that `unixToIso` cannot convert (non-finite numbers) falls back to the original value instead of null, through `unixToIso(value) ?? value`.
**Rationale**: The cell then shows what the server sent rather than a misleading blank or placeholder that would hide bad data.
**Approved**: pending

**Decision**: The function does no null formatting, stringification or truncation; it returns `unknown`.
**Rationale**: Those belong to each list surface (`cellText` renders an em dash, stringifies and truncates at 80 characters), which keeps this function a single-purpose conversion shared by `CrudTable` and `CrudDataView` (separation of concerns).
**Approved**: pending

**Decision**: Out-of-range finite seconds are not guarded, so the `RangeError` from `Date` propagates.
**Rationale**: The source adds no guard; the throw is visible rather than swallowed, and the `/v1` API serving real timestamps keeps the case unreachable in practice. A port should match this unless the caller decides otherwise.
**Approved**: pending

**Decision**: The output is a UTC ISO string, not a localized date.
**Rationale**: It matches the ISO strings the other timestamp columns already show, so every timestamp in a list reads in one form. Localized display is not part of the source.
**Approved**: pending

