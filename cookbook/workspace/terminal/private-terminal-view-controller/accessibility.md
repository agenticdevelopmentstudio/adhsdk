
- **Role/trait**: The eye and the accessory toggle are buttons with explicit accessibility labels ("Show the private terminal", and "Hide the private terminal" or "Show the private terminal" for the accessory) and the identifiers `privateTerminal.reveal` and `privateTerminal.toggleVisibility`. The options button has the identifier `privateTerminal.options.editWords`.
- **Label requirements**: The eye symbol is created with the accessibility description "Show the private terminal" and the tooltip carries the same text; the accessory button's label and tooltip change with the state.
- **Announce state changes**: Not implemented as an announcement; the accessory title and message change, and no accessibility notification is posted by this class.
- **Terminal contents**: The terminal sits in the concealed container, so no accessibility element, children, visible children or hit-test result below it is exposed. This is deliberate; the open question on `screen-reader-contents` records the consequence.
- **screen-reader-contents**: NEEDS REVIEW: Not implemented in source. A screen-reader user can lift the screen but then finds no readable terminal; evidence that settles it is a product decision on whether private panes are meant to be unusable with a screen reader and, if not, a design for an alias-only accessible rendering.
- **Minimum tap target**: The eye symbol is 48 points; the accessory eye is 13 points with no minimum hit area set in this class, so the 44 by 44 point target is not asserted by the source.
- **Keyboard**: The terminal takes keyboard focus on reveal; the source adds no keyboard shortcut to reveal or hide.

