
- **render-items**: The component MUST render each item in the `items` array as an interactive tab.
- **mark-active-tab**: The component MUST mark the tab matching the `value` prop as active, setting `aria-selected="true"` and the `data-active` attribute on that tab only.
- **render-icon-if-provided**: If an `AppTab` in `items` has an `icon` property, the component MUST render it within the tab.
- **render-label**: The component MUST render the `label` ReactNode for each tab.
- **invoke-callback-on-click**: When a user clicks any tab — including `endItem` — the component MUST call `onValueChange` (if provided) with that tab's `id`; `endItem` shares the same click handler as every other item, so clicking it invokes `onValueChange` exactly like any other tab.
- **render-end-item-if-provided**: If `endItem` is provided, the component MUST render it at the trailing edge of the tab bar.
- **respect-end-item-active-state**: The `endItem` tab MUST use its own `active` property independently of the `value` prop; it MUST NOT be marked active based on `value` matching its `id`.
- **apply-role-tablist**: The root container MUST have `role="tablist"`.
- **apply-role-tab-to-items**: Each rendered tab button MUST have `role="tab"`.
- **apply-class-name**: The component MUST apply the `className` prop to the root container if provided.
- **no-content-panels**: The component MUST NOT create or manage content panels; each tab is a self-contained interactive element with no associated panel to show or hide. (The React implementation satisfies this by rendering plain `<button>` elements rather than a Base UI `<Tabs>` component — see Platform Notes.)

