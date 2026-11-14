
`PaneContentSpacingConsuming` is a main-actor, class-bound protocol with one
method, `applyPaneSpacing(_:)`. Pane content adopts it when the content insets
itself. The source gives the example of a terminal, which holds its grid off its
own edges because a theme may override that padding.

The protocol settles who applies the gap between a pane's edge and its content.
The rule in the source is "one gap, not a second padding stacked on the first".
Content that adopts the protocol is handed the app-wide pane-content spacing
(`PaneSpacing.contentSpacing`) and does the insetting, and its pane pins it
flush. Content that does not adopt it has the gap applied for it, by the pane.
Exactly one of the two applies the gap. The choice is made by a conformance, not
by the pane knowing what a terminal is.

The protocol itself draws nothing. The pane that decides between the two paths
is `PaneViewController.applyResolvedSpacing()`, and the two adopters in the
source are the terminal content controllers.

