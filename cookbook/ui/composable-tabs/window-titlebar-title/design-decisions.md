
**Decision**: The title is a leading titlebar accessory that replaces the platform's centred title instead of decorating it.
**Rationale**: Per the source comment, the platform draws the centred title without an icon, so the only way to show an icon before the name, as a pane's title bar does, is to hide the platform's title and draw our own at the leading edge.
**Approved**: pending

**Decision**: The window's `title` is still set to the name even though it is not drawn.
**Rationale**: Per the source comment, the Window menu and accessibility read that property, so it must keep carrying the name.
**Approved**: pending

**Decision**: The width is set from the stack's fitting size, capped by the window's width minus a fixed 160 points.
**Rationale**: Per the source comment, a leading accessory is as wide as its view's frame, so the title must be sized by hand: its own width, but never more than the window leaves after the trailing accessories and window controls, so a long title truncates instead of running under them.
**Approved**: pending

**Decision**: The reserved width is a fixed constant, not measured from the actual trailing accessories.
**Rationale**: The source keeps 160 points for the trailing accessories (a settings gear) and window controls with no measurement; this is recorded as the design as built, not an invention of intent.
**Approved**: pending

**Decision**: The icon is hidden from accessibility.
**Rationale**: The icon sits beside a label that already names the window, so the icon is treated as decoration and carries no accessibility description of its own.
**Approved**: pending

