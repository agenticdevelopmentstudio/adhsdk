
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded, not looked up by key) | `"non-HTTP response"` | Literal string embedded in `Failure.transport("non-HTTP response")`, produced when `perform`'s response cannot be cast to `HTTPURLResponse`. It is English-only and not routed through any string catalog or localization mechanism. |

`Failure.transport(String(describing: error))`'s other payload comes from the
underlying `Error`'s own, unlocalized description — it is not authored by
`ADHSyncAPI` and carries whatever language `URLError`/`Error` produces.

