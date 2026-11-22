
Not applicable: the files contain no log calls. Failures surface only as a nil result (`ModelTierTarget.init`, `ClaudeCodeVersion.init`, `LossyDecoded.value`, `select`), a `false` (`isValidId`), a refusal sentence (`problem`, `removalProblem`), a `ModelRouterTemplateDecodeError` (`decodeFile`), a thrown decoding error, or empty data (`encodedFile`). The doc comment on `problem` records that names are printed raw by `steno router` and copied into every routing-log row, which is why names are screened.

| Event | Level | Message |
|-------|-------|---------|
| (none) | — | — |

