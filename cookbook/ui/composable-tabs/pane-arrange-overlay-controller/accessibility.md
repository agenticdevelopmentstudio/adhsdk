
- **Role/trait**: The toggle is a standard `NSButton` with an image-only appearance; the overlay's controls are in `ComposableTabsArrangeOverlayView`.
- **Label requirements**: The toggle's symbol carries the accessibility description "Arrange Panes", and the button has the tooltip "Arrange panes" and the accessibility identifier it is initialized with.
- **Announce state changes**: NEEDS REVIEW: Not implemented in source. The toggle's on and off state is set on the button and shown by tint, but no announcement of entering or leaving arrange mode is made and the tint is the only mode indicator on the button; a VoiceOver pass and the overlay view's own labels would settle whether the mode is conveyed another way.
- **Keyboard**: Arrow keys move the selected pane, and Return, Enter and Escape leave the mode, as above.
- **Minimum tap target**: NEEDS REVIEW: Not implemented in source. The toggle is 36 by 24 points. Whether a 24-point-tall target is acceptable is the platform guideline's call and the source cannot decide it.

