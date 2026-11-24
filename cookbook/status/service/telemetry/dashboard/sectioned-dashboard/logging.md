
The module logs failures with `console.warn` and nothing at other levels.

| Event | Level | Message |
|-------|-------|---------|
| A section loader rejected | warn | `[telemetry] dashboard section <name> (<key>) failed: <error>` |
| The refresh failed outside a section (the loaders builder threw, or `mapLimit` rejected) | warn | `[telemetry] dashboard refresh (<key>) failed: <message>` |

