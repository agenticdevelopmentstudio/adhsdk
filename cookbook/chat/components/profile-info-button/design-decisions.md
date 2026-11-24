
**Decision**: Render a plain anchor with `target="_blank"` and `rel="noopener noreferrer"` instead of a button that calls `window.open`.
**Rationale**: The control navigates, so a link gets keyboard activation, middle-click, copy-link and status-bar URL from the browser. `noopener noreferrer` keeps the profile page from reaching back into the chat page and from receiving its URL.
**Approved**: pending

**Decision**: Hide the "i" glyph from assistive technology and put the name on `aria-label`, repeated in `title`.
**Rationale**: A lone letter would be announced as "i", which tells a screen reader user nothing; the label names the destination. `title` gives sighted pointer users the same text as a tooltip.
**Approved**: pending

**Decision**: Split the component and its stylesheet, and make the stylesheet opt-in, with `--pc-pi-size` and `--pc-pi-inset` as the only knobs.
**Rationale**: Hosts that do not show the button pay nothing for its CSS, and the two knobs are all a theme needs to resize it or move it clear of a differently rounded corner. Colors reuse the chat theme tokens so no theme needs button-specific colors.
**Approved**: pending

**Decision**: Position the button with absolute coordinates and a minus 50% translate, so half of it overhangs the frame's top edge, and render it outside `.persona-chat`.
**Rationale**: The overhang is what makes the button read as perched on the corner, and its opaque face hides the border beneath it. The cost, as the component's comment states, is that `.persona-chat` can be `overflow: hidden` (the mobile overlay mode sets it), which would clip the overhang, so the host must place the button as a sibling in the outer `position: relative` wrapper.
**Approved**: pending

**Decision**: Wrap the implementation in `memo` (SHOULD, not MUST).
**Rationale**: The host chat re-renders on every streamed token while this button's props never change after mount, so memoizing avoids that work. Skipping it is only a performance loss, not a behavior change, which is why it is a SHOULD.
**Approved**: pending

**Decision**: Replace the default outline with a border color change and glow on hover and `:focus-visible`, and keep the 0.18s transition (SHOULD).
**Rationale**: The source gives hover and keyboard focus the same highlight, which suits the circular shape better than a rectangular outline. The transition is cosmetic, so an implementation may drop it. Whether the glow is a sufficient focus indicator is an open question and is not settled here.
**Approved**: pending

