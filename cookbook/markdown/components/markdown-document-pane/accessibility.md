
- **Role/trait**: The pane root and body are plain `div` elements with no role of their own. The bar's toolbar is labeled "Editing actions" (the Button Bar's default `ariaLabel`, observed in the pane's test); the editor owns the Source and Preview semantics.
- **Label requirements**: The pane adds no labels. A host that renders two panes on one page must rely on the editor's `subject` prop (forwarded) to tell the layout controls apart.
- **Announce state changes**: The pane announces nothing itself; save errors, gone and conflict notices are rendered by the bar.
- **Keyboard path**: Every interactive control is inside the bar or the editor; the pane adds none and does not intercept keys.
- **Minimum tap target**: Not applicable: the pane has no controls of its own; target sizes are set by the bar's buttons and the editor.

