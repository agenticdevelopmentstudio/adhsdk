
**Ref Forwarding**
**Decision**: The component uses `forwardRef` to expose the root `HTMLDivElement` to parent consumers.
**Rationale**: This enables advanced layout control (e.g., measuring the pane's dimensions) without importing the component directly. This is a common React pattern for layout-sensitive components.
**Approved**: pending

**Empty Alt Strings For Images**
**Decision**: When image data lacks an `alt` attribute, the component assigns an empty string rather than a fallback description.
**Rationale**: This is correct for decorative images but relies on the data source to provide meaningful alt text for content images. Consumers MUST ensure image data includes descriptive alt text.
**Approved**: pending

**Link Opening Behavior**
**Decision**: Links always open in a new tab (`target="_blank"`) with security attributes (`rel="noopener noreferrer"`).
**Rationale**: This prevents the three-pane layout from being interrupted when a user follows a link, while `rel="noopener noreferrer"` blocks reverse-tabnabbing. Consumers SHOULD signal this behavior to users — for example by appending "opens in a new tab" to a link's accessible name, or by pairing the link with an icon that carries an equivalent accessible label — since neither the component nor the anchor markup announces it on its own.
**Approved**: pending

**Connector Anchor Placement**
**Decision**: The ConnectorAnchor is rendered at the start of the title, using a CSS class (`pc-connector-anchor-in`) to position it visually. The message index is embedded in the anchor's `data-connector-anchor` attribute (registered with `ConnectorRegistry`, not exposed as a DOM `id`) to support bidirectional linking in the three-pane layout.
**Rationale**: This design ties the pane's visual structure to the message flow; changes to title structure may require updates to the anchor positioning.
**Approved**: pending

**Conditional Rendering Of Sections**
**Decision**: Images and links sections only render if their arrays are non-empty.
**Rationale**: This keeps the UI clean when data is sparse. Consumers should expect variable content heights and plan layout accordingly.
**Approved**: pending

**Visibility Is Styling Only, Focus Left Untouched**
**Decision**: Hiding the pane is expressed entirely as a class name (`pc-pane-hidden`) on the root element. The component deliberately keeps its content mounted, applies no `inert`/`aria-hidden`/`tabIndex`, and never calls `focus()`.
**Rationale**: This keeps the component free of effects and lets the layout animate the pane in and out without losing scroll position or image decode state. The shipped `pc-pane-hidden` style (`opacity: 0; pointer-events: none;`) keeps the connector anchor's box measurable while the pane is offscreen, which `display: none` would defeat by collapsing it to zero — but unlike `visibility: hidden`, it does not remove the pane from the accessibility tree or the tab order, leaving open the question on **Focus across visibility transitions** of whether a hidden pane's links should stay keyboard-reachable.
**Approved**: pending

