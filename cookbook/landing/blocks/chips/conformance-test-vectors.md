
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| chips-001 | list-rendering, base-list-styling | `{ entries: [{ label: "Chip A" }], soon: false }` | `<ul class="lp-chips">` contains rendered entries |
| chips-002 | list-item-rendering, item-label-content | `{ entries: [{ label: "Chip A" }, { label: "Chip B" }] }` | Two `<li>` elements rendered; first contains "Chip A", second contains "Chip B" |
| chips-003 | active-item-state | `{ entries: [{ label: "Active", open: true }] }` | `<li class="lp-chip--open">` contains "Active" |
| chips-004 | inactive-item-state | `{ entries: [{ label: "Default" }] }` | `<li>` (no `lp-chip--open` class) contains "Default" |
| chips-005 | upcoming-list-variant | `{ entries: [{ label: "Coming Soon" }], soon: true }` | `<ul class="lp-chips lp-chips--soon">` rendered |
| chips-006 | default-list-variant | `{ entries: [{ label: "Available" }], soon: false }` | `<ul class="lp-chips">` (no `lp-chips--soon` class) |
| chips-007 | default-list-variant | `{ entries: [{ label: "Available" }] }` | `<ul class="lp-chips">` (no `lp-chips--soon` class) |
| chips-008 | list-rendering | `{ entries: [] }` | `<ul class="lp-chips"></ul>` (empty list) |
| chips-009 | active-item-state, inactive-item-state | `{ entries: [{ label: "First", open: true }, { label: "Second" }] }` | First `<li class="lp-chip--open">` contains "First"; second `<li>` (no `lp-chip--open`) contains "Second" |
| chips-010 | item-label-content | `{ entries: [{ label: <strong>Bold</strong> }] }` | `<li>` renders the `<strong>Bold</strong>` element as-is, not stringified |
| chips-011 | active-item-state, upcoming-list-variant | `{ entries: [{ label: "Both", open: true }], soon: true }` | `<ul class="lp-chips lp-chips--soon">` contains `<li class="lp-chip--open">Both</li>`; the item's active state and the list's upcoming variant apply independently |

