
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `RUNTIME_ERROR_WINDOW_MS` | number (exported constant) | 86,400,000 | The window one read covers. |
| `RUNTIME_ERROR_REPORT_CAP` | number (exported constant) | 200 | Most groups in a report. |
| `RUNTIME_LEVELS` | readonly string array | fatal, error, warning, info, debug, trace | Level ranking, worst first. |
| message head limit | number (private constant `MESSAGE_MAX`) | 200 | Characters kept in a head and a shape. |
| `projects` | map of project id to `RuntimeProject` (name, domain) | none (required) | Injected into the entry builders; the production-project filter. |
| `store` | `Pick<RuntimeErrorsStore, "load" \| "lastRead">` | none (required) | Injected into `loadRuntimeErrorsReport`. |
| `nowMs` | number | `Date.now()` | Clock for `generatedAt`. |

