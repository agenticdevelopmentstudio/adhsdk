
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-pill-001 | accept-children | `<StatusPill>Active</StatusPill>` | Component renders the text "Active" within the pill |
| status-pill-002 | base-style | `<StatusPill>Free</StatusPill>` | Root element has CSS class `lp-status` |
| status-pill-003 | accent-style | `<StatusPill free={true}>Free Plan</StatusPill>` | Root element has both classes `lp-status` and `lp-status--free`, giving it `border-color: var(--lp-status-free-border)` and `background: var(--lp-accent-dim)` |
| status-pill-004 | accent-opt-in | `<StatusPill>Standard</StatusPill>` | Root element has class `lp-status` only; `lp-status--free` is absent |
| status-pill-005 | accent-opt-in | `<StatusPill free={false}>Standard</StatusPill>` | Root element has class `lp-status` only; `lp-status--free` is absent |
| status-pill-006 | status-conveyed-by-text | `<StatusPill free={true}>Free Plan</StatusPill>` | The rendered text content reads "Free Plan" regardless of the `free`-driven border and background, so the status is legible with color and border removed |

