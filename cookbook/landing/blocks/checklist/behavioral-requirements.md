
- **group-structure**: Component MUST accept an array of `ChecklistGroup` objects, each containing a `heading` (ReactNode) and `items` array of `ChecklistItem` objects.
- **heading-element**: Component MUST render the heading for each group as an `<h3>` element.
- **item-structure**: Component MUST render each item in a group as an `<li>` element, wrapping the item's `text` (ReactNode) in a `<span>`.
- **empty-group-omits-list**: Component MUST NOT render a `<ul>` element for groups with zero items; the group div and heading still render.
- **soon-class**: Component MUST support an optional `soon` boolean property on items; when `soon` is true, the item's `<li>` element MUST receive the `lp-checklist__item--soon` CSS class.
- **root-class**: Component MUST apply the `lp-checklist` CSS class to the root container div.
- **stable-group-order**: Callers MUST NOT reorder, insert into, or remove from the `groups` or `items` arrays between renders. The component keys both by array index (see **Map index as key** in Design Decisions), so element identity across such changes is not guaranteed.

