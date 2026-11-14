
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `active` | boolean | (required) | True when the live feed is dark (unreachable); false when connection is healthy. Controls visibility and state of the overlay. |
| `onRetry` | function | (required) | Callback invoked when the user clicks "Try again now" or when the 15-second countdown reaches 0. Receives no arguments. |
| `detail` | string \| null | undefined | Optional error detail text displayed only after the grace period (elapsedMs >= 90000) expires. If null or undefined, the detail section is not rendered. |

`elapsedMs` (outage duration) is not a configurable option — it is internal state derived from `active` and the show delay, not a prop. See the note at the top of Behavioral Requirements for exactly how it is measured and reset.

