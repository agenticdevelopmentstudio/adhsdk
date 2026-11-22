
`AccountRouterRuleFilter.unknown(_:)` returns a hardcoded English sentence, which the query decoder uses as the debug description of its data-corrupted error. The daemon's `GET /router/exchanges` route does not decode the DTO; it refuses an unknown `rule` query parameter with its own English 400 sentence built from `validList` (`rule must be one of <validList>`). Neither is localized.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none: inline literal) | `Unknown rule "<raw>"; use one of <validList>.` | Refusal for a routing-log rule filter that is not a known raw value |

