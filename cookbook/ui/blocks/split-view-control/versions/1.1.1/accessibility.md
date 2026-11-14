
- **Roles**: Each toggle group is a segmented control / buttonset; individual items are toggle buttons
- **Label requirements**: Layout toggle has `aria-label="${subject} layout"`; pane toggle has `aria-label="${subject} pane"`; individual toggle items have `aria-label` and `title` attributes
- **Pane control association**: Pane toggle items have `aria-controls="${panesId}"` pointing to the container element wrapping the two panes (not placed on individual hidden panes)
- **Announce visibility**: The layout toggle is not rendered on narrow viewports, so the control renders a smaller footprint — no aria-hidden needed for the unrendered toggle
- **Title attributes**: Both layout toggle items have `title` attributes for mouse hover: "Single tabbed view" and "Side by side view"
- **Hidden separator**: When the separator is not rendered, it is not in the DOM; no `aria-hidden` needed
- **Minimum touch/click target**: Handled by the ToggleGroup and ToggleGroupItem components; SplitViewControl assumes the underlying component meets the WCAG minimum target size (44×44px) — this is a web component, so iOS and Android platform minimums do not apply

