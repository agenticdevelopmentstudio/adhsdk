
Not applicable beyond the arguments below: the module reads no environment variables, settings or injected dependencies.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `range` | `AnalyticsRange` | none; callers choose (the analytics route defaults to `"7d"`) | Which window `rangeWindow` builds |
| `nowMs` | number (epoch ms) | none | The clock reading the window is anchored to; the caller supplies it |
| `buckets` | readonly string array | none | The axis `alignToBuckets` fills, normally `RangeWindow.buckets` |
| `points` | iterable of `[unknown, number]` | none | Timestamp and value pairs to sum onto the axis |

