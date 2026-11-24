
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Tabs.defaultValue` | `string \| number` | `0` | Uncontrolled: which tab is active on initial render. Base UI defaults to index `0`, not a specific tab's `value` |
| `Tabs.value` | `string \| number` | — | Controlled: the active tab's value; pairs with `onValueChange` |
| `Tabs.onValueChange` | `(value: string \| number) => void` | — | Called when the user selects a different tab, so a controlled `value` can be updated |
| `TabsList.activateOnFocus` | `boolean` | `false` | Whether moving focus with arrow keys also changes the selected tab (`true`); by default, arrow keys move focus only and selection requires a separate click/activation |
| `Tabs.className` | `string` | `undefined` | Additional CSS classes merged into the root `Tabs` element via `cn()` |
| `TabsList.className` | `string` | `undefined` | Additional CSS classes merged into the `TabsList` element via `cn()` |
| `TabsTab.value` | `string \| number` | required | Identifies this tab; matched against `TabsPanel.value` to associate content |
| `TabsTab.disabled` | `boolean` | `false` | Blocks click-activation for this tab; no visual change is applied (see **disabled-tabs**) and the tab remains keyboard-focusable |
| `TabsTab.className` | `string` | `undefined` | Additional CSS classes merged into this tab's classes via `cn()` |
| `TabsPanel.value` | `string \| number` | required | Identifies which tab's content this panel renders |
| `TabsPanel.className` | `string` | `undefined` | Additional CSS classes merged into this panel's classes via `cn()` |

