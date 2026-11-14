
| State | Behavior |
|-------|----------|
| Closed | Summary visible; answer hidden. Disclosure triangle/icon points right (or icon is neutral). Clicking or pressing Enter/Space toggles to open. |
| Open | Summary visible; answer visible below. Disclosure triangle/icon points down. Clicking or pressing Enter/Space toggles to closed. |
| Focused (keyboard) | When summary receives keyboard focus (via Tab), the summary element shows focus indicator (browser or CSS-defined). |

The component does not manage state internally — all state changes are handled by the browser's native `<details>` element.

