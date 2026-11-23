
**Decision**: The source view uses a small in-house HTML highlighter with
theme colors, not a third-party highlighter or the code editor.
**Rationale**: The HTML is the gatekeeper's own narrow output (a fixed set
of tags and one attribute pattern), so four token kinds cover it; no new
dependency.
**Approved**: pending

**Decision**: Agent views rebuild only while shown; switching a tab into
an agent view always builds afresh.
**Rationale**: A walk per trigger on tabs nobody is looking at would cost
time for nothing, and building on entry still meets `refresh-triggers` for
what the user sees.
**Approved**: pending

**Decision**: The preview is given its own web view rather than reusing
the tab's, and the live page's web view is kept, hidden, while an agent
view is shown.
**Rationale**: A separate, sealed configuration (scripts off, block-all
rules) cannot be applied to the live page; keeping the live view meets
`website-mode-restores-page`.
**Approved**: pending

**Decision**: Rendering an unavailable page uses the gatekeeper's own
HTML rendering of it rather than a separate view.
**Rationale**: The views must show the gatekeeper's output and nothing
else, failures included.
**Approved**: pending

**Decision**: An agent view reads the page with a reading walk that keeps
the agent's ref table, never a snapshot walk.
**Rationale**: Looking at what the agent sees must not change it: a
snapshot walk would renumber the refs the agent holds from its last
snapshot.
**Approved**: pending

