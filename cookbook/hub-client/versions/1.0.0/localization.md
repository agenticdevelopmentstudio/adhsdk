
| String Key | Default (en) | Context |
|-----------|---------------|---------|
| (none — inline literal) | `not an ISO-8601 date: <text>` | Debug description built in `JSONDecoder.adhDefault`'s custom `dateDecodingStrategy`, thrown inside `DecodingError.dataCorrupted` when a date string matches neither the fractional nor the plain ISO-8601 format. English-only, not routed through any string catalog or localization mechanism. |

