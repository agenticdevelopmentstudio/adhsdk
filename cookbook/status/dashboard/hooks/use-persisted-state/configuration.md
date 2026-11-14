
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `key` | string | none — required | The local-storage key; each setting owns its own key (the dashboard's keys include `adh-status-show-canceled`, `adh-status-in-progress-or-failed-only` and `adh-status-stats-span`, and the source filter takes its key from the caller). |
| `initial` | value of the state's type | none — required | The value before hydration and whenever storage yields nothing usable. |
| `decode` | function from an unknown value to the value or `undefined` | none — required | Turns parsed JSON into the value; `undefined` means "not recognised, keep the default." |
| `encode` | function from the value to JSON-serialisable data | identity | Turns the value into what is written; needed when the value has no JSON form of its own (a set, an object holding a derived field). |

The state reads no environment variables or settings keys beyond these arguments, and its only injected dependency is the browser's local storage, resolved as a global at the time of each read or write.

