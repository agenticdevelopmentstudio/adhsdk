
SplitDivider is a bare separator primitive that allows users to resize the space between two panes by dragging a divider or using keyboard controls. It reports a ratio (0–1) representing the fraction of the split given to the leading pane (above for horizontal, left for vertical). The component owns neither the panes nor any collapse state; the caller renders the regions and applies the ratio to layout. It is designed for layouts like search results / preview panes or repository tree / activity log pairs.

