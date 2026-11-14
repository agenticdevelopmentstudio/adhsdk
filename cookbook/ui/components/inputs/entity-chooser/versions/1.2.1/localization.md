
`EntityChooser` renders user-provided `options` as-is and takes its display strings through caller-provided props, but three of them fall back to hardcoded English defaults when the caller omits them:

| String Key | Default (en) | Context |
|---|---|---|
| `triggerLabel` | `Choose…` | Trigger text when no `triggerLabel` prop is passed; also what the trigger shows for a `null` single value. |
| `emptySelectionLabel` | `Nothing selected yet` | Multi-mode hint shown when the set is empty and no `emptySelectionLabel` prop is passed. |
| chip `removeLabel` | `Remove <value>` | Built by `EntityChooser`/`EntitySelectionChips` from the chip's value; not itself overridable — a caller localizing `<value>` upstream localizes this label too. |

Callers targeting a non-English locale MUST pass `triggerLabel` and `emptySelectionLabel` explicitly rather than rely on the English defaults.

