
| State | Appearance change |
|---|---|
| Single, value set | trigger shows the value; the matching list row shows ✓ when open |
| Single, value null | trigger shows the trigger label (e.g. "Choose…") |
| Multi, empty set | empty-selection hint (e.g. "Nothing selected yet", the default) + the Choose trigger |
| Multi, non-empty set | one chip per entry + the Choose trigger |
| Browser open | `ListChooser` popover: focused field, filtered list, OK/Cancel |
| `allowCreate` off, no match | no create row; OK disabled; Enter a no-op |
| Disabled | trigger + chip-remove controls dimmed and non-interactive |

The control is synchronous over the in-memory `options` prop — loading/error states
belong to the caller that fetches the options (mirroring `ListChooser` /
`RecipientInput`).

