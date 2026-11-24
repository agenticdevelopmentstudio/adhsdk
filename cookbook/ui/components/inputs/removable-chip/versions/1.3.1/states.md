
| State | Appearance change |
|---|---|
| Rest | Badge in its `variant` tone; ✕ muted (`text-apt-text-muted`) |
| ✕ hover | ✕ brightens to `text-apt-text` |
| ✕ focus-visible | Native button focus indicator on the ✕ |
| Disabled | ✕ disabled + `pointer-events-none` (does not fire `onRemove`). The `Badge` body is unaffected — it keeps rendering its normal `variant` tone; `Badge` receives no `disabled` prop. |

