
| State | Appearance change |
|-------|------------------|
| Loading | Shows "Loading…" text at 60% opacity; no form |
| Ready | Full form visible with email and optional name fields; submit button enabled |
| Submitting | Submit button disabled and at 50% opacity; button text changes to "Signing up…"; aria-busy="true" |
| Done | Form hidden; success message displayed with focus |
| Closed | Message "{list name} is closed to new signups right now." (`config?.name ?? "This list"`: falls back to "This list" only when config.name is `null` or missing/`undefined`; an empty-string `config.name` renders as a blank subject, e.g. " is closed to new signups right now.") ; no form |
| Unavailable | Error message "Signups are unavailable right now." with a "Try again" button |

