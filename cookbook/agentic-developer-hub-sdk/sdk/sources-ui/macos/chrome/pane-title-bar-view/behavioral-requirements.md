
- **render-title-label**: The component MUST render a text label displaying the current title text.
- **truncate-title-in-middle**: The component MUST truncate the title text in the middle (not at trailing edge) when the available width is insufficient to display the full title.
- **sync-tooltip-with-title**: The component MUST set the title label's tooltip to the full title text when the title is non-empty, and clear it (set to nil) when the title is empty.
- **render-fixed-height**: The component MUST have a fixed height of 26pt and MUST NOT resize vertically based on content.
- **leading-controls-cluster**: The component MUST include a `PaneControlCluster` positioned at the leading edge, 6pt from the leading edge, vertically centered within the bar.
- **bottom-separator**: The component MUST render a 1pt hairline separator spanning the full width of the bar, pinned to the bottom edge, using the themed border color.
- **support-accessory-views**: The component MUST support an ordered array of accessory views positioned between the title and the gear control.
- **replace-accessory-views-atomically**: When the accessory views array is replaced, the component MUST remove all previous accessory views from the view tree and add all new views in the provided array order.
- **support-optional-gear-view**: The component MUST support an optional gear view supplied by the pane owner and positioned at the trailing edge, with a default trailing margin of 6pt from the pane edge.
- **gear-trailing**: When a gear view is present, the component MUST keep it at the trailing edge and constrain all other content to its leading side, maintaining a 6pt gap between the accessory stack and the gear.
- **center-content-vertically**: The component MUST vertically center all child elements (controls, title label, accessory views, gear view) within the bar.
- **honor-yield-width-request**: When `yieldWidthToContainer()` is called, the component MUST set the content compression resistance priority of itself and all subviews (depth-first) to the lowest value (1) for the horizontal axis, allowing the container to constrain its width without resistance.
- **apply-yield-to-future-subviews**: When width-yielding is enabled, any accessory views or gear views added after the call to `yieldWidthToContainer()` MUST also have their compression resistance priority set to the lowest value for the horizontal axis.
- **accessory-spacing**: The component SHOULD maintain 4pt spacing between consecutive accessory views.

