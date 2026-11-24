
- **Roles**: Each toggle group is a `role="group"` containing toggle buttons that expose their state with `aria-pressed`; exactly one item per group is pressed, and re-pressing it does not clear it
- **Label requirements**: Layout toggle has `aria-label="${subject} layout"`; pane toggle has `aria-label="${subject} pane"`; individual toggle items have `aria-label` and `title` attributes
- **Pane control association**: Pane toggle items have `aria-controls="${panesId}"` pointing to the container element wrapping the two panes (not placed on individual hidden panes)
- **Announce visibility**: The layout toggle is not rendered on narrow viewports, so the control renders a smaller footprint — no aria-hidden needed for the unrendered toggle
- **Title attributes**: Both layout toggle items have `title` attributes for mouse hover: "Single tabbed view" and "Side by side view"
- **Hidden separator**: When the separator is not rendered, it is not in the DOM; no `aria-hidden` needed
- **Minimum touch/click target**: Handled by the ToggleGroup and ToggleGroupItem components; the toggle items are 32px tall with a 32px minimum width, which meets WCAG 2.2 AA target size (2.5.8, 24×24 CSS px) but not the AAA target size (2.5.5, 44×44 CSS px); the control targets AA — this is a web component, so iOS and Android platform minimums do not apply

