
`ProgressSummary` in `@adh-sdk/ui` is a count line over a `Progress` bar. It takes `done` and `total`, shows "`{done} of {total} {label} done`" (`label` defaults to "items") and the percentage rounded down (0 when `total` is 0). The bar's accessible name is the same sentence, and its indicator is green when `done === total` and `total > 0`.
