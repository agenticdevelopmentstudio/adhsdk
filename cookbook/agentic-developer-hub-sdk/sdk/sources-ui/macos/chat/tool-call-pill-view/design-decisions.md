
**Decision**: The component uses `.info` (neutral blue) for the running state rather than `.warning` (yellow/orange).
**Rationale**: This prioritizes reduced alert fatigue: a running command is neither good news nor bad, and using a warning color would create false urgency on every tool call. This differs from error indicators (red / `.danger`) and success indicators (green / `.success`), which are meaningful outcomes.
**Approved**: pending

**Decision**: When a command fails, the error message is appended to the name using a space–em dash–space separator (`" — "`), producing `"<name> — <message>"`.
**Rationale**: This is consistent with the error handling approach taken in `MessageBubbleView` for failed message deliveries: a colored pill with no words requires the user to decode the color; the message makes the failure legible.
**Approved**: pending

**Decision**: Truncated text does not display a tooltip showing the full text.
**Rationale**: This is consistent with the source code, which has no tooltip implementation. A tooltip would improve UX for long error messages but is out of scope for this component.
**Approved**: pending

**Decision**: The component holds its own `ThemePaletteObserver` and recolors in place on palette changes, rather than relying on a full view-tree rebuild.
**Rationale**: This is a performance optimization for live theme switching in a transcript view: pills already rendered remain on screen and update their colors directly, reducing layout churn.
**Approved**: pending

