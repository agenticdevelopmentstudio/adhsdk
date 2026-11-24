
- **role**: The control's segments are radio buttons, described by their items' titles (the initialiser's documentation states this; the titles reach assistive technology as each segment image's accessibility description).
- **identifier**: The control carries the caller's `accessibilityID` as its accessibility identifier.
- **labels**: Every segment has a title as its accessibility description and as its tooltip.
- **state-announcement**: The selected segment is the control's selected segment, so assistive technology reads selection from AppKit's own control; the component adds no announcement.
- **keyboard-access**: NEEDS REVIEW: Not implemented in source. The control sets `refusesFirstResponder` and turns the focus ring off, so no keyboard path reaches the segments; evidence that would settle it is whether the caller offers another keyboard route to switch panels or whether Full Keyboard Access is expected to cover it.
- **target-size**: NEEDS REVIEW: Not implemented in source. Segments are 32 points wide and the height is the control's intrinsic height; whether that meets the project's pointer target size is a design decision this source cannot make, and a measured intrinsic height would settle it.
- **contrast**: NEEDS REVIEW: Not implemented in source. The selection colour is the theme's accent and the track is a system shade; whether the symbol on the accent meets contrast for every built-in theme can only be settled by measuring each theme's accent against the control's symbol colour.

