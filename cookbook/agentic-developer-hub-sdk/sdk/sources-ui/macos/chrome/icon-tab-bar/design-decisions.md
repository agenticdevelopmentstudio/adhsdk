
**Decision**: Use AppKit's own `NSSegmentedControl` rather than drawing a custom bar.
**Rationale**: The source's comment cites `native-controls`: the control gives Xcode's navigator-selector look, hit testing and accessibility for free.
**Approved**: pending

**Decision**: The caller owns the choice. After every click the bar puts back whatever `selectedID` last said, then calls `onSelect`.
**Rationale**: The source comment says the bar puts back what the caller last said until it answers, so a refused pick does not stay drawn.
**Approved**: pending

**Decision**: The control refuses first responder and shows no focus ring, so a click leaves the keyboard where it was.
**Rationale**: A panel with a list to type into keeps the keyboard; the caller moves it there itself. The cost, noted in the open question on `keyboard-access`, is that the bar has no keyboard path of its own.
**Approved**: pending

**Decision**: The track appearance follows the palette's window background brightness (below 0.5 is dark), not the system appearance.
**Rationale**: The source comment says a dark theme gets the dark track whatever the system is set to. A background that cannot be converted to sRGB counts as bright, so it falls to the light track.
**Approved**: pending

**Decision**: Segments are a fixed 32 points wide, and the bar is exactly its control with required horizontal hugging.
**Rationale**: The source comment says a caller that centres the view gets a bar that hugs its icons, sized to them rather than to the space it sits in.
**Approved**: pending

**Decision**: A symbol that cannot be resolved becomes an empty image instead of an error.
**Rationale**: The initialiser falls back to a blank image so a bad symbol name never prevents the bar from being built. Technical debt: the failure is silent, so a mistyped symbol shows as a blank segment with only its tooltip.
**Approved**: pending

