
- **Empty entries array**: Component renders an empty `<ul class="lp-chips"></ul>` with no list items (see **list-rendering**).
- **Undefined `soon` property**: Treated as not `true`; the upcoming variant is not applied (see **default-list-variant**). Component renders with its baseline styling only.
- **Undefined `open` property on entry**: Treated as not `true`; no active-item modifier is applied to that list item (see **inactive-item-state**).
- **Mixed active states**: Some entries have `open: true`, others do not. Each entry's active-item modifier is applied independently of the others (see **active-item-state**, **inactive-item-state**; chips-009).
- **ReactNode label**: The `label` prop accepts any ReactNode (string, number, element, fragment, etc.). Component renders it as-is without validation or transformation (chips-010).
- **Null, undefined, or boolean label**: React does not render `null`, `undefined`, `true`, or `false` children, so the list item renders with empty content in that case; the `<li>` element itself is still emitted. An empty string likewise renders as empty content. Numeric `0` renders as the text "0", since React does treat `0` as a renderable child.

