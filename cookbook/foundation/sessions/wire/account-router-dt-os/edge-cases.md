
- **Empty item key**: `isRoutable("")` MUST return false (no colon, so no kind).
- **Name with colons**: `isRoutable("oauth:a:b")` MUST return true; only the first colon splits kind from name.
- **Unknown kind prefix**: a key like `api:x` MUST be refused, even though it has a colon and a name.
- **Empty pool and credentials**: a status with `pool: []` and `savedCredentials: []` MUST decode and encode without error.
- **Older daemon**: a status missing every tuning key and `models` MUST decode with the defaults (60, 300, true, true, 30, nil); a report missing `models` MUST decode with nil.
- **Missing required status key**: a status missing any of the seven required keys MUST fail to decode rather than defaulting.
- **Limit boundaries**: `limit` 1 MUST yield 1, 1000 MUST yield 1000, 1001 MUST yield 1000, 0 MUST yield 1, and `Int.min` MUST yield 1, with no overflow (`max` then `min`).
- **sinceHours boundaries**: the query carries 0, negatives and `Int.max` unchanged; the DTO SHOULD NOT clamp them because the daemon interprets them (0 or less is all time; `AccountRouterRecordTests.testSinceHoursLimitsTheWindowAndZeroOrLessIsAllTime` shows the daemon clamps `Int.max` without overflow).
- **Account `-`**: `account: "-"` MUST be read as "verbatim rows", so a real item key `-` cannot be queried; `isRoutable("-")` is false, so no pooled credential has that key.
- **Rule as non-string**: a numeric `rule` MUST throw a type-mismatch decoding error, not the unknown-rule refusal.
- **Rule null**: `"rule": null` MUST decode as nil.
- **retriedAccount with the marker earlier in the rule**: only the last `(retry after ` counts; an earlier one followed by other text MUST NOT be matched.
- **retriedAccount with status 0 or negative**: the suffix is built from the integer as given (` 0)`, ` -1)`), so a rule ending that way MUST match it; no status validation is done.
- **Out-of-range preference values**: the DTO MUST carry them unchanged; refusal is the daemon's job.
- **Duplicate accounts in a preference write**: the DTO MUST carry duplicates unchanged; the daemon de-duplicates.
- **Concurrent access**: every DTO and the rule filter are immutable or value-semantics `Sendable` values, `AccountRouterItemKey` has no state, and every function is pure, so concurrent use needs no ordering rule.
- **Error states**: the only failures are decoding errors (key-not-found, type-mismatch, and the data-corrupted unknown rule), which MUST be thrown to the caller; nothing is swallowed.
- **Offline or disconnected state**: not applicable; these types perform no I/O. Transport failures belong to the client and daemon that carry them.

