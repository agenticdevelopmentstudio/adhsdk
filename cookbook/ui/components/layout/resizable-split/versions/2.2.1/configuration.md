
| Option | Type | Default | Description |
|---|---|---|---|
| `top` | `React.ReactNode` | — | Top pane content (required). |
| `bottom` | `React.ReactNode` | — | Bottom pane content (required). |
| `defaultRatio` | `number` | `0.6` | Initial top fraction (0..1), clamped to `[minRatio, maxRatio]`. |
| `minRatio` | `number` | `0.2` | Lower clamp bound (0..1). |
| `maxRatio` | `number` | `0.85` | Upper clamp bound (0..1). |
| `storageKey` | `string` | — | When set, persist the ratio in `localStorage[storageKey]` on drag release; restore on mount. |
| `collapsed` | `boolean` | — | Controlled collapse state of the bottom pane; the component is controlled whenever this prop is defined (`collapsed !== undefined`). When omitted, the visible state comes from internal state. |
| `onCollapsedChange` | `(collapsed: boolean) => void` | — | Called whenever collapse state changes (via chevron click), in both controlled and uncontrolled configurations. If provided without a controlled `collapsed` prop, the caller must feed the value back for the visible state to update. |
| `bottomLabel` | `string` | `"Details"` | Accessibility label for the chevron button (`aria-label`). |
| `header` | `React.ReactNode` | — | When set, render the divider as the bottom pane's header bar with this left-aligned content; triggers header-bar variant. |
| `headerActions` | `React.ReactNode` | — | Right-aligned interactive controls on the header bar, before the chevron; never drag targets. Setting this also triggers header-bar variant. |
| `expandToContent` | `boolean` | `true` (header bar), `false` (seam) | On expand-from-collapsed, size the bottom pane to show all its content (clamped to `[minRatio, maxRatio]`). |
| `className` | `string` | — | Additional CSS classes applied to the container. |

Collapse state is internal whenever `onCollapsedChange` is not provided. The ratio is always internal, seeded from `storageKey` or `defaultRatio`, and persisted on drag release.

