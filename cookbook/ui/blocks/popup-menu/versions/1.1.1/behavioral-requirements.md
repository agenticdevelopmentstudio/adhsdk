
- **accept-items**: The component MUST accept an array of `PopupMenuItem` objects, each with `id` (string) and `label` (string).
- **accept-selected-id**: The component MUST accept `selectedId` as a string or null; null represents the "All" (nothing focused) state.
- **call-select-callback**: When an item is selected in the dropdown, the component MUST invoke the `onSelect` callback with the item's id (or null for "All").
- **render-all-row-when-enabled**: When `allLabel` is not null, the component MUST render an "All" row in the dropdown as the first item, with the provided label.
- **omit-all-row-when-disabled**: When `allLabel` is null, the component MUST omit the "All" row entirely.
- **render-new-row-when-callback-present**: When the `onNew` callback is provided, the component MUST render a divider followed by a "New…" row at the bottom of the dropdown, and invoke `onNew` when selected.
- **omit-new-row-when-no-callback**: When `onNew` is not provided, the component MUST omit the "New…" row and its divider entirely.
- **display-selected-label-on-trigger**: The trigger MUST display the label of the currently selected item, or the `allLabel` if `selectedId` is null, or an empty string if no "All" label is configured.
- **single-select-item-group**: All `PopupMenuItem` entries, and the "All" row when present, MUST be rendered within one single-selection group, so that choosing one entry deselects any previously selected entry and the currently selected entry is marked as checked.
- **truncate-long-trigger-labels**: Long labels on the trigger MUST be truncated with a visible ellipsis so overflowing text does not spill outside the trigger's bounds.
- **accept-aria-label**: The component MUST accept an `ariaLabel` prop and apply it to the trigger element for assistive technology.
- **hide-icon-from-accessibility**: The trigger's icon (default or custom) MUST be excluded from assistive-technology announcements, so it is not read aloud redundantly alongside the trigger's label.
- **default-affordance-icon**: When no custom `icon` prop is provided, the component MUST render a default dropdown affordance icon indicating that the trigger opens a menu.
- **accept-custom-icon**: The component MUST accept a custom `icon` prop (ReactNode) and render it in place of the default affordance icon.
- **accept-trigger-class-name**: The component MUST accept a `className` prop and merge it with the trigger's built-in classes such that consumer-supplied classes override the defaults.
- **warn-on-sentinel-collision**: If any item in the `items` array has an id equal to the value reserved internally to represent the "All" state, the component MUST log a warning identifying the collision.
- **focus-indicator-contrast**: When the trigger receives keyboard focus, the component MUST replace the default browser focus outline with a visible border-color change meeting WCAG 2.4.7 (focus visible) and 1.4.11 (non-text contrast, 3:1 minimum) against the adjacent surface.

