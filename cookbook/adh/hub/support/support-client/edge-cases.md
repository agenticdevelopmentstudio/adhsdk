
- **Switch off (MUST)**: the grants read is 404 while the backend's `consented_access` switch is off; the client rethrows, `useSupportGrants` stops retrying, and `isSupportOff` lets a caller hide its surface.
- **A lapsed request (MUST)**: a request undecided for seven days or more is read as `ended` by `grantState`, whatever the backend has recorded yet. The seven days are the exported constant `SUPPORT_LAPSE_DAYS`, which mirrors the backend's `support:lapsed` rule that a request not decided in seven days is treated as denied.
- **Empty and absent ids (MUST)**: the read hooks (all but `useOperatorSupportGrants`) are disabled and make no request.
- **A write that fails (MUST)**: a refusal is rethrown unchanged; nothing is invalidated, because each hook invalidates on success only.
- **A malformed path in the log (MUST)**: `accessTable` decodes each of the `{schema}` and `{table}` segments, and keeps a segment whose escapes are malformed as it was logged rather than throwing, so one odd row never stops the log from rendering.
- **A refused table (MUST)**: a 404 from the viewer path reaches the caller as the transport's error; the client does not fall back to another route, and `useSupportData` does not retry.
