
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| checklist-001 | group-structure | groups array with one group `{ heading: "Group 1", items: [{ text: "Feature A" }] }` | Renders `div.lp-checklist` containing an `h3` with text "Group 1" and one `li` containing a `span` with text "Feature A" |
| checklist-002 | heading-element | groups array with heading "Group 1" | `h3` element contains heading text "Group 1" |
| checklist-003 | item-structure | group with items array `[{ text: "Item A" }, { text: "Item B" }]` | `ul` renders two `li` elements, each containing a `span` with the respective text |
| checklist-004 | empty-group-omits-list | group with empty items array `[]` | `h3` heading renders, but no `ul` element is rendered for that group |
| checklist-005 | soon-class | item with `{ text: "Coming soon", soon: true }` | `li` element receives class `lp-checklist__item--soon` |
| checklist-006 | soon-class | item with `{ text: "Available", soon: false }` or `soon` undefined | `li` element does not receive the `lp-checklist__item--soon` class |
| checklist-007 | root-class | any valid groups array | root `div` element has class `lp-checklist` |
| checklist-008 | group-structure | groups array `[{ heading: "First", items: [{ text: "A" }] }, { heading: "Second", items: [{ text: "B" }] }]` | Component renders a separate `div` for each group, in the same order as the input array: "First" precedes "Second" |
| checklist-009 | stable-group-order | render with `groups = [{ heading: "A", items: [{ text: "1" }] }, { heading: "B", items: [{ text: "2" }] }]`, then re-render with the same groups reordered to `[B, A]` | Rendered content matches the new order ("B" then "A"); the component provides no guarantee that element identity for a given group or item follows it across the reorder, since keys are by array index |

