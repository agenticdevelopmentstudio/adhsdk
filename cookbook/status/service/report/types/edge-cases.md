
- A source that throws is uncovered, becomes one major finding, and clears `complete`; the other sources are still read and their sections stay populated.
- A report with no findings and `complete` false has verdict `unknown`, never `healthy`; "no findings" is not a clean bill of health when a source was not fully read.
- `logs` accepts the forms `true`, `false`, `1`, `0` from in-process callers, and only `0` or `1` from a query string; the strings `true` and `false` are rejected (see `params-logs-forms`).
- An empty string for any param is treated as absent, so `?days=` takes the default.
- `days` and `wait` accept only whole decimal digits with an optional minus sign; `1e1`, `1.5` and `0x10` are rejected.
- The type module's header comment names `src/report/build.ts` as the place the judgements are made; the code lives in the report rules module. The contract here is unaffected.

