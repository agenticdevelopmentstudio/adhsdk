
- **tablist-rendering**: Component MUST render a `role="tablist"` when the `tabs` array has length > 0.
- **nav-links-rendering**: Component MUST render a `<nav aria-label="views">` when the `links` array has length > 0.
- **empty-tabs-omit-tablist**: Component MUST NOT render a `role="tablist"` when the `tabs` array is empty.
- **empty-links-omit-nav**: Component MUST NOT render a `<nav>` when the `links` array is empty.
- **active-tab-marking**: Component MUST set `aria-selected="true"` on the tab whose `value` matches the current `value` prop; all other tabs MUST have `aria-selected="false"`.
- **tab-click-callback**: Component MUST call the `onChange` callback with the tab's `value` when a tab button is clicked.
- **active-link-marking**: Component MUST set `aria-current="page"` on the link whose `active` prop is `true`; other links MUST NOT have this attribute.
- **active-state-attribute**: Component MUST set `data-active=""` (empty string) on both tab buttons and links when they are in the active state; the attribute MUST NOT be present on inactive items.
- **tab-role-attribute**: Component MUST render each tab button with `role="tab"`.
- **icon-tab-label**: Component MUST apply the `title` prop as both the `aria-label` and `title` HTML attribute on each tab button to provide accessible labels when the visible label is an icon.
- **container-class-merge**: Component MUST accept a `className` prop and merge it with its own layout classes on the outermost container element via the `cn()` utility.
- **layout-spacing**: Component MUST lay out both the inner tablist row and the nav row as a flex row with bottom-aligned items and a consistent horizontal gap between them; the outer container MUST apply horizontal padding around the whole strip. (Web implementation: `flex items-end gap-4` on each row, `px-4` on the container — see Appearance.)
- **item-styling**: Component MUST apply one consistent style class to every tab button and link element so all items render uniformly, distinguished only by the active-state attribute. (Web implementation: `tabItemClass` from the Tabs component — see Appearance.)
- **reactnode-labels**: Component MUST accept `ReactNode` for both tab and link labels, supporting text, icons, or composed elements.

