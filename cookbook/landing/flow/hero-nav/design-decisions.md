
**Decision**: Render the links as plain anchors with no click handler, and let the lens be the only script.
**Rationale**: The doc comment says the hrefs then work the same with JavaScript off; navigation is a table of contents and needs no script.
**Approved**: pending

**Decision**: Draw separators as `span` elements, `aria-hidden`, rather than a border.
**Rationale**: The source comment says a border would also draw at the ends of a wrapped line; an element can be omitted before the first link, and being hidden keeps assistive technology reading only the links.
**Approved**: pending

**Decision**: Remove the separators and use a 1.2rem column gap below 640px.
**Rationale**: The `flow.css` comment says that when the row wraps a bar lands at the end of one line or the start of the next with nothing on its far side, and the test cites mikefullerton's contact row as the precedent.
**Approved**: pending

**Decision**: Pass the lens colour token names (`--lp-ink-dim`, `--lp-accent-bright`) rather than resolved values.
**Rationale**: The doc comment says the names are resolved where the row is mounted, so a repaint of the tokens repaints the sweep.
**Approved**: pending

**Decision**: Start the sweep 2000 ms after mount, once.
**Rationale**: The doc comment says the lens says the line is alive and worth clicking; the delay lets the hero settle first. The lens, once started, keeps sweeping back and forth (the doc comment's phrase "swept once" describes the single start, not a single pass). The 2000 ms value is stated in the source without a recorded reason, and the hook applies it to the first sweep only (a later effect run uses 0 ms).
**Approved**: pending

**Decision**: Take `rows` as a prop shaped like the page's own sections instead of a free list.
**Rationale**: The doc comment says `indexRows(page)` is meant to be passed so a row cannot name a band the page lacks or miss one it has.
**Approved**: pending

**Decision**: SHOULD requirements (separators as elements; hover colour) follow the source's comments and CSS.
**Rationale**: Deviation is allowed because the nav still works with borders or another hover colour; the cost is a dangling bar on wrapped lines and a hover that no longer lands where the sweep does.
**Approved**: pending

