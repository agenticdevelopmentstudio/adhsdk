
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `iso` (bucket functions) | string | none — required | An ISO 8601 timestamp for the start of a bucket. |
| `range` (bucket functions) | `"24h"`, `"7d"` or `"30d"` | none — required | Chooses the hour format (`"24h"`) or the day format (the others). |
| `vital`, `value` (vital-formatting function) | a web vital (`"lcp"`, `"inp"`, `"cls"`, `"fcp"`) and a number | none — required | The vital picks the unit; the value is the raw measurement. |
| `body` (listed-sites function) | an object that may carry `views.sites`, or `undefined` | none — required | A dashboard response body, or the absence of one. |
| `sites`, `site` (with-site function) | a read-only list of strings and a string or `null` | none — required | The server's list and the site the URL names. |
| `reports`, `site`, `none` (site-report function) | a read-only record, a string and a fallback value | none — required | The server's per-site reports, the URL's site and what to return when there is none. |
| Hour format | constant | English, two-digit hour and minute, 24-hour cycle, UTC | Fixed in the module. Not configurable. |
| Day format | constant | English, short month and numeric day, UTC | Fixed in the module. Not configurable. |
| Seconds threshold | constant | `1000` | Values at or above this are written in seconds. Not configurable. |

The module reads no environment variables or settings keys and takes no injected dependency.

