
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `actions` | `ButtonBarActions` (optional) | `undefined` | Preset editing actions object. When provided and `children` is not provided, the preset action flow renders. |
| `showCreate` | `boolean` | `true` | Controls visibility of the Create button when rendering preset actions. |
| `showDelete` | `boolean` | `true` | Controls visibility of the Delete button when rendering preset actions. |
| `leading` | `ReactNode` | `undefined` | Content to render before action buttons or children (e.g., a pane title). |
| `children` | `ReactNode` | `undefined` | Arbitrary content that overrides preset actions when provided. |
| `ariaLabel` | `string` | `"Editing actions"` | Accessible label for the toolbar. |
| `className` | `string` | `undefined` | Additional CSS classes merged with base styling. |

### `ButtonBarActions` shape

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `onCreate` | `() => void` | No | `undefined` | Called when the Create button is clicked. Omit together with `showCreate={false}` for panes that don't create here; the Create button and its separator do not render without it. |
| `createLabel` | `string` | No | `"New"` | Overrides the Create button's label. |
| `onCancel` | `() => void` | Yes | — | Called when the Cancel button is clicked. |
| `canCancel` | `boolean` | Yes | — | Enables the Cancel button when `true` (and `saving` is `false`). |
| `onSave` | `() => void` | Yes | — | Called when the Save button is clicked. |
| `canSave` | `boolean` | Yes | — | Enables the Save button when `true` (and `saving` is `false`); also drives the `ghost`-variant/muted-text swap when disabled. |
| `saving` | `boolean` | No | `false` | While `true`, disables Delete/Cancel/Save and changes the Save label to `"Saving…"`; Create is not disabled by this flag (see **create-not-disabled-while-saving**). |
| `onDelete` | `() => void` | No | `undefined` | Called when the Delete button is clicked. Omit together with `showDelete={false}` for panes that don't delete here; the Delete button does not render without it. |
| `canDelete` | `boolean` | No | `undefined` (falsy) | Enables the Delete button when `true` (and `saving` is `false`); an omitted value renders Delete as disabled whenever it is shown. |

