
The session produces two hardcoded English fallback strings that reach the UI, and no externalised strings. A port keeps the literals unless its owner localises them.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | `tool` | Tool name shown when a tool event has no name or an unknown id |
| none (literal) | `error` | Failure text when an error result has neither `resultText` nor `subtype` |

