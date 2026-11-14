
`EntityChooser` renders user-provided `options` as-is and takes its display strings through caller-provided props, but three of them fall back to hardcoded English defaults when the caller omits them:

| String Key | Default (en) | Context |
|---|---|---|
| `placeholder` | `ListChooser` default (inherited) | Filter/add field placeholder when no `placeholder` prop is passed. |
| `createLabel` | `ListChooser` default (inherited) | Create-row label when no `createLabel` prop is passed. |
| `emptyLabel` | `ListChooser` default (inherited) | Browser "no matches" message when no `emptyLabel` prop is passed. |
| `triggerLabel` | `Choose…` | Trigger text when no `triggerLabel` prop is passed; also what the trigger shows for a `null` single value. |
| `emptySelectionLabel` | `Nothing selected yet` | Multi-mode hint shown when the set is empty and no `emptySelectionLabel` prop is passed. |
| chip `removeLabel` | `Remove <value>` | Built by `EntityChooser`/`EntitySelectionChips` from the chip's value; not itself overridable, which is a known gap: a caller can localize `<value>` but not the word "Remove", and no `removeLabel(value)` prop exists yet. |

Callers targeting a non-English locale MUST pass `triggerLabel`, `emptySelectionLabel`, `placeholder`, `createLabel` and `emptyLabel` explicitly rather than rely on the English defaults.

