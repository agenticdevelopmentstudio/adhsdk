
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storageKey` | `string` | `adh-sdk:color-mode` | `localStorage` key for the persisted choice; the legacy fallback applies only to the default |
| `defaultMode` | `ColorMode` | `auto` | Mode used when nothing valid is stored |
| `children` | `ReactNode` | required | Subtree that receives the context |

Fixed constants: cycle order `auto`, `dark`, `light`; legacy key `agentic-toolkit:color-mode`; cycle event `awt:appearance-cycle`; changed event `awt:appearance-changed`; media query `(prefers-color-scheme: dark)`; document class `dark`; document attribute `data-appearance-mode`.

