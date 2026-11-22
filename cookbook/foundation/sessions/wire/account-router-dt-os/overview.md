
`AccountRouterDTOs.swift` declares, inside the `Sessions` namespace, the data shapes the account router exchanges between the daemon (its `/router/*` routes), the `steno router` CLI and the Settings panel. The account router pools saved Claude credentials and hands each routed request to one of them; these types are how its state, its usage report, its routing log and its preference writes cross a process boundary.

The file holds:

- `AccountRouterItemKey.isRoutable(_:)`: the single test for "an item key the account router may pool", shared by the daemon (which refuses anything else), the CLI and the Settings panel (which offer only these).
- `AccountRouterPoolEntryDTO`: one pool entry, as `steno router status`, `GET /router/status` and the Settings panel show it.
- `AccountRouterStatusDTO`: the router's whole state, with tolerant decoding of older daemons.
- `AccountRouterReportRowDTO` and `AccountRouterReportDTO`: the per-account usage report, plus `retriedAccount(in:status:)`, which pulls the account a retry hid out of a routing-rule string.
- `AccountRouterExchangeDTO`: one routing-log row.
- `AccountRouterRuleFilter`: the routing log's rule filter.
- `AccountRouterExchangeQueryDTO`: one routing-log question, with the effective page size and a decoder that refuses an unknown rule by name.
- `AccountRouterExchangePageDTO`: one page of the routing log.
- `AccountRouterPreferencesRequestDTO`: a partial settings write.

Every type here is secret-free by construction: none has a field that could hold a token, header value or request body. Item keys are spelled by [adhsdk.ingredient.foundation.claude-accounts.claude-credential-kind](cookbook:d457c4d4-005c-4fcb-a3a6-3e1680bcb561). The model-routing types these DTOs nest (`ModelRouterStatusDTO`, `ModelUsageRowDTO`, `ModelRouterPreferencesDTO`, `ModelThreadKind`) live in `ModelRouterDTOs.swift` and are outside this recipe.

