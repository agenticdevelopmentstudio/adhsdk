
**Decision**: Panes claim a slot and portal their control into the header rather than the stack drawing the control.
**Rationale**: The source explains that the pane that knows the endpoint and the help text is several components below the stack that draws the header, so the pane claims a slot and portals in; the stack cannot know either.
**Approved**: pending

**Decision**: The last claimant of a kind wins, and an unmount withdraws only its own claim.
**Rationale**: The source says this is the same rule as the detail title, and it keeps a closing pane from stripping the header out from under the pane now open; it also guarantees one header never shows two API buttons.
**Approved**: pending

**Decision**: The two slot elements are held in state, not in refs.
**Rationale**: The source explains that a ref lands during commit without a re-render, so the provider would publish null on the mount that matters and every claimant would stay invisible.
**Approved**: pending

**Decision**: Every header always draws the API and help pair, disabled with a stated reason when nothing is claimed.
**Rationale**: The source says every header keeps the same `[API][?]` shape on its right and says why there is nothing to open, so the layout never shifts and the user is told why a control is unavailable.
**Approved**: pending

**Decision**: The disabled tooltips sit on a wrapper element, and the reason is repeated in the accessible name.
**Rationale**: The source comment states that a disabled button swallows pointer events, so the tooltip lives on a wrapper; the reason in the name is what a screen-reader user hears in place of the tooltip.
**Approved**: pending

**Decision**: The stack's `actions` live in their own box and are not claimable.
**Rationale**: The source says the stack that owns the view owns these, so no pane below can displace them, and a server-rendered node arrives as a child of a client component, which React flagged as a keyless list child when it sat bare beside the two slots.
**Approved**: pending

