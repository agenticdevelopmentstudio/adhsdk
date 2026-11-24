
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | `String` | none | The line to type; escaped before use. `nil` on `script(for:text:raising:)` builds the select-only variant. |
| `termProgram` | `String` | none | The terminal's `TERM_PROGRAM` value; only `iTerm.app` and `Apple_Terminal` are accepted. |
| `termSessionId` | `String` | none | The `TERM_SESSION_ID` value; the part after the last `:` is the iTerm session uuid. Ignored for Terminal.app. |
| `pid` | `Int` | none | A process in the session, used to find its controlling TTY when no iTerm session id is known and always for Terminal.app. |
| `raising` | `Bool` | `false` on `inject`; required on `script(for:text:raising:)` | Whether the pane is selected and its application brought forward. |
| `returnDelay` | `Duration` | 300 milliseconds | The pause between typing and the Return. It is internal (not public) and constant. |

The component reads no environment variable and no settings key; the caller passes the `TERM_PROGRAM` and `TERM_SESSION_ID` values in.

