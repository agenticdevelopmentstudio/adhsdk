
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | toggle-on-header-click | click the header | children show, then hide |
| T2 | support-uncontrolled | `defaultOpen` only | manages its own state |
| T3 | support-controlled | `open={false}` and an `onOpenChange` that ignores the call; click the header | callback fires once; children stay unmounted |
| T4 | rotate-chevron | open it | chevron gains `rotate-90` |
| T5 | actions-exempt-from-toggle | click a button in `actions` | disclosure state unchanged |
| T6 | mount-children-only-when-open | collapsed | children absent from the DOM |
| T7 | toggle-on-header-click | Enter/Space on the focused header | children show, then hide |
| T8 | expose-expanded-state | inspect the toggle button after opening and closing | `aria-expanded` matches the current open state |

