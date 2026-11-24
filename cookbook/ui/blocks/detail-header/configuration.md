
`DetailHeaderProvider`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `fallbackHelp` | `ReactNode` | `undefined` | The stack's own help, shown in the help slot while no pane claims it. |
| `actions` | `ReactNode` | `undefined` | Controls about the whole view, drawn just left of the API and help pair on every header row the stack draws; not claimable. |
| `children` | `ReactNode` | (required) | Everything the stack draws, so panes below can claim the slots. |

`DetailHeaderRow`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `lead` | `ReactNode` | `undefined` | The stack's control for the detail: a cover toggle or a Back button. |
| `leadCell` | `boolean` | `false` | Seats `lead` in a fixed 32px wide cell so a cover toggle lines up with the rails' toggles. |
| `tools` | `ReactNode` | `undefined` | The stack's other controls for the detail, beside `lead` (such as the cover-all control). |
| `title` | `DetailStripTitle` | `undefined` | Names what the detail shows; its `cell` is a pane's hoisted title or the stack's own. |

`DetailHeaderPortal`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `kind` | `"api" \| "help"` | (required) | Which slot to claim. |
| `children` | `ReactNode` | (required) | The control to draw in the slot. |

`DisabledApiButton`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `reason` | `string` | "This view has no API endpoint" | Tooltip and the tail of the accessible name. |

`DisabledHelpButton`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `reason` | `string` | "No help for this view" | Tooltip and the tail of the accessible name. |
| `triggerClassName` | `string` | `undefined` | Extra classes merged last into the button. |

The constants `NO_API_ENDPOINT` and `NO_HELP` hold the two default reasons. `DetailHeaderHost` has `apiSlot`, `helpSlot`, `apiOwner`, `helpOwner` and `claim(id, kind, claimed)`.

