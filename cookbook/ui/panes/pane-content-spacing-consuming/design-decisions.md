
**Decision**: Choose who applies the gap by a protocol conformance, not by the pane inspecting what kind of content it holds.
**Rationale**: The source comment names this (`explicit-over-implicit`): the pane never learns what a terminal is, and any content that insets itself opts in by adopting the protocol.
**Approved**: pending

**Decision**: Exactly one party applies the gap: the content when it conforms, otherwise the pane, with the pane pinning conforming content flush.
**Rationale**: The source states the rule as "one gap, not a second padding stacked on the first"; letting both apply would double the padding.
**Approved**: pending

**Decision**: The gap is one app-wide setting, not per pane or per content type, and a terminal's padding is that same setting.
**Rationale**: The source says there is one inner margin, not one for terminals and another for everything else, and a window spaced differently from its neighbor reads as a bug. The legacy terminal padding is migrated into it.
**Approved**: pending

**Decision**: The gap is handed over again on every pane-content setting change, and the pane's resolve step assigns rather than accumulates.
**Rationale**: The doc comment says the method is called again whenever the setting changes, and the pane's comment cites idempotency, so repeated calls are safe.
**Approved**: pending

**Decision**: The terminal conformers use the call as a trigger to reapply appearance instead of using the `Spacing` value directly.
**Rationale**: The source says a theme may override the padding, so the terminal resolves the padding inside its appearance step, where the theme and the setting are both read.
**Approved**: pending

