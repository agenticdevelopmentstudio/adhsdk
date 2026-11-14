
- **Empty items array**: If `items` is an empty array, the component renders the tab list container but no tab buttons. EndItem (if provided) still renders.
- **Value not in items**: If `value` does not match any `id` in `items`, no tab is marked active (all have `aria-selected="false"`). This is valid; the component does not error.
- **Missing onValueChange**: If `onValueChange` is undefined, the optional-chaining call (`onValueChange?.(t.id)`) is skipped entirely — clicking is a no-op that does not throw. The tab remains interactive; the component does not guard against a missing callback beyond this optional chaining.
- **Items array mutation**: The component uses `.map()` over `items` on each render. If `items` is mutated (not replaced), the component reflects the current array state on next render.
- **EndItem with no active property**: If `endItem` is provided without an `active` property, it renders with `aria-selected` derived from `!!undefined`, which is false. The endItem tab is not active.
- **Icon is falsy**: If `icon` is `null`, `undefined`, or `false`, nothing is rendered for that slot; the label still renders.

- **EndItem placement in right-to-left layouts**: `endItem` is pushed to the trailing edge with the physical `ml-auto` utility, not a logical one (`ms-auto` / `margin-inline-start`). In a `dir="rtl"` context the class does not mirror, so `endItem` stays on the visual right instead of moving to the trailing (left) edge. See Design Decisions and Platform Notes.
- **Duplicate ids in `items`**: Unsupported; the component does not check. React reports duplicate-key warnings, and every item whose `id` equals `value` is marked active (`t.id === value` is evaluated per item), so several tabs can be active at once.
