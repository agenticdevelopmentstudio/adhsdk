
- **fixed-width**: Component MUST render at exactly 28 points wide.
- **restore-button**: Component MUST display a restore button with a plus symbol (`+`) at the top.
- **glyph-display**: Component MUST display a glyph or symbol representing the minimized pane's content.
- **restore-callback**: Component MUST invoke the `onRestore` callback when the restore button is tapped.
- **symbol-name**: Component MUST accept a `symbolName` property to specify which SF Symbol to display as the glyph.
- **glyph-tracks-symbol**: Component MUST update the displayed glyph immediately when `symbolName` property changes.
- **tooltip**: Component MUST accept a `tooltip` property that appears on hover over the glyph.
- **tooltip-tracks-property**: Component MUST update the tooltip text immediately when the `tooltip` property changes.
- **hairline-inward**: Component MUST place a vertical separator hairline on the interior side (inward) based on the edge the pane docks to—trailing side if pane docks to leading edge, or leading side if pane docks to trailing edge.
- **glyph-fallback**: Component MUST display a dashed square (`square.dashed`) when the provided `symbolName` is invalid or unavailable.
- **theme-colors**: Component MUST observe theme changes and update button and glyph colors to secondary text color from the current theme palette.
- **accessibility-labels**: Component MUST set accessibility label "Restore Pane" on the restore button and provide accessibility description based on tooltip or "Minimized Pane" for the glyph.

