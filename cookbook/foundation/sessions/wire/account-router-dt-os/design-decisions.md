
**Decision**: Every DTO is secret-free by construction: no field can hold a token, header value or body, and the exchange's `error` is scrubbed before it is stored.
**Rationale**: The status, report and log are shown in a CLI, a Settings panel and over HTTP; a type with no place for a secret cannot leak one, which the routes test checks by asserting no `sk-ant` in the status body.
**Approved**: pending

**Decision**: `AccountRouterStatusDTO` decodes each tuning row and `models` with a default when absent, while the seven core keys stay required.
**Rationale**: "A daemon older than the tuning rows sends none of them: each reads as its default," so a newer client can read an older daemon; the core keys have no meaningful default.
**Approved**: pending

**Decision**: The status property is `baseUrl`, not Swift-idiomatic `baseURL`.
**Rationale**: Convert-from-snake-case turns `base_url` into `baseUrl`; `baseURL` would not round-trip.
**Approved**: pending

**Decision**: An unknown routing-log rule is refused with a sentence listing the valid ones, not a generic decoding error.
**Rationale**: A caller decoding a query sees which values are accepted rather than a bare type error; the daemon's route refuses an unknown query-string rule the same way, with a sentence built from `validList` (`testAnUnknownRuleIs400ListingTheValidOnes`).
**Approved**: pending

**Decision**: `effectiveLimit` lives on the query DTO and clamps to 1…1000 with a default of 200.
**Rationale**: "`limit` as the daemon applies it": clients can compute the page size the daemon will use without duplicating the clamp.
**Approved**: pending

**Decision**: `AccountRouterItemKey.isRoutable` is the one routable-key test, shared by the daemon, the CLI and the Settings panel, and a legacy bare-name key is never routable.
**Rationale**: One definition keeps what the UI offers and what the daemon accepts from drifting; a bare name has no kind to route by.
**Approved**: pending

**Decision**: `retriedAccount(in:status:)` is a port of model-router `cli.py`'s trailing-marker regex, matching only the last `(retry after <name> <status>)` and rejecting overlap, empty and whitespace-containing names.
**Rationale**: The report must count 429s a retry hid against the account that answered them, read from the stored rule string, matching the original tool's behavior.
**Approved**: pending

**Decision**: `AccountRouterPreferencesRequestDTO` documents ranges but does not enforce them.
**Rationale**: Validation, with user-facing sentences, is done once by the daemon's `AccountRouterPreferences.setAccountRouter`, so every client gets the same refusal; the DTO stays a plain partial-write shape where nil means "leave as is".
**Approved**: pending

**Decision**: `sinceHours` of nil, 0 or less means all time, and `account` `-` means verbatim rows.
**Rationale**: Sentinels keep the query flat and optional-only; `-` cannot collide with a routable key because `isRoutable("-")` is false.
**Approved**: pending

