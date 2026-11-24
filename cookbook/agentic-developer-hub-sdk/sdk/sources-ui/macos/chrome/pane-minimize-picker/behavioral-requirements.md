
- **render-four-arrows**: The component MUST render exactly four arrow buttons arranged in a cross pattern: top, leading, trailing, and bottom.
- **initialize-with-available-edges**: The component MUST accept an initial set of available edges at initialization and enable only those arrows.
- **disable-unavailable-arrows**: The component MUST disable arrow buttons for edges not in the available edges set.
- **invoke-callback-on-selection**: The component MUST invoke the onPick callback with the selected edge when an arrow is tapped.
- **close-popover-before-callback**: The component MUST close the popover before invoking the onPick callback.
- **support-dynamic-availability**: The component MUST update button enabled states when the available edges set is changed after initialization.
- **apply-theme-tint**: The component MUST apply primary text color to enabled arrows and tertiary text color to disabled arrows based on the current theme.
- **display-tooltips**: Each arrow button MUST display a tooltip with the edge's display name.

