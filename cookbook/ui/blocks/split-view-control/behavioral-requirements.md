
- **layout-toggle-visible-on-wide-viewport**: On viewports ≥ 64rem, the control MUST render a layout toggle group with two options: tabbed (single pane) and split (side by side).
- **layout-toggle-hidden-on-narrow-viewport**: On viewports < 64rem, the control MUST NOT render the layout toggle group.
- **separator-between-toggles-in-tabbed-mode**: When the layout toggle is rendered AND the effective layout is tabbed, the control MUST render a vertical separator (1px, `bg-apt-border` color) between the layout toggle and the pane toggle; it MUST NOT render the separator when the effective layout is split.
- **pane-toggle-visible-only-in-tabbed-layout**: The pane toggle group (edit/preview) MUST render when the effective layout is tabbed and MUST NOT render when the effective layout is split (both panes are already visible).
- **layout-preference-persists-across-viewport-changes**: The user's layout preference MUST be retained when the viewport narrows below 64rem and restored when widening above 64rem.
- **effective-layout-demoted-on-narrow-viewport**: On narrow viewports, the effective layout MUST be "tabbed" regardless of the stored layout preference.
- **edit-label-customizable**: The edit toggle label MUST be customizable via the `editLabel` prop, defaulting to "Edit".
- **preview-label-customizable**: The preview toggle label MUST be customizable via the `previewLabel` prop, defaulting to "Preview".
- **flex-row-layout**: The control MUST render as a flex row with items center-aligned and 0.75rem (gap-3) spacing between children.
- **empty-toggle-selection-ignored**: When a user clicks a toggle group item that is already selected, the toggle group hands back an empty array; the control MUST ignore this event and retain the current selection.
- **layout-toggle-group-aria-label**: The layout toggle group MUST have an `aria-label` that reads `"${subject} layout"` where `subject` is the component-provided context string.
- **pane-toggle-group-aria-label**: The pane toggle group MUST have an `aria-label` that reads `"${subject} pane"`.
- **pane-toggle-aria-controls-container**: Each pane toggle item MUST have an `aria-controls` attribute pointing to the ID (`panesId`) of the pane container element (placed on the container, not on individual hidden panes).
- **layout-toggle-item-accessible-names**: The layout toggle items MUST have matching `title` and `aria-label` values: "Single tabbed view" for the tabbed item, "Side by side view" for the split item.
- **tabbed-icon-is-square**: The tabbed layout toggle MUST display a Square icon.
- **split-icon-is-columns2**: The split layout toggle MUST display a Columns2 icon.
- **edit-icon-is-pencil**: The edit pane toggle MUST display a Pencil icon before its label.
- **preview-icon-is-eye**: The preview pane toggle MUST display an Eye icon before its label.

