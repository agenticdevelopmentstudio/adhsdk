
| State | Appearance change |
|-------|------------------|
| Default | Not rendered — the `Popup` is unmounted (inside the `Portal`) while the tooltip is closed |
| Visible | Rendered with full styling, positioned adjacent to trigger |
| Arrow visible | Diamond pointer visible (default state when arrow=true) |
| Arrow hidden | No pointer element rendered (when arrow=false) |

The component defines no CSS transition or animation on open/close, so there is no separate opening/closing transition state; visibility changes are an instant mount/unmount via the Portal.

