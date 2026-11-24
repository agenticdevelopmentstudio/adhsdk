
The set itself makes no log call; the underlying cache logs a section failure as `[telemetry] dashboard section <name> (<key>) failed: <error>` through `console.warn`.

