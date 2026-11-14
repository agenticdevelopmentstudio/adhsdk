
**Decision**: Dispatch to child layout components (`InlineChat`, `ThreePaneChat`, `MobileChat`) via a plain `switch` statement on `mode`, rather than a polymorphic factory pattern.
**Rationale**: The three modes represent fundamentally different UI layouts (embedded box, side-by-side panes, full-screen overlay), not interchangeable implementations of the same interface, and each has distinct prop requirements (`sizing` for inline; `open`/`onClose` for mobile), making a unified prop interface unwieldy. The component remains thin and transparent — a presentation-level router with no business logic beyond routing.
**Approved**: pending

**Decision**: Mode is a caller-supplied prop (`mode: ChatMode`), not state PersonaChat tracks internally.
**Rationale**: Mode selection is caller-determined, allowing parent components to choose layout based on viewport, user preference, device type, or application state.
**Approved**: pending

**Decision**: An unrecognized `mode` value falls through the `switch` and `PersonaChat` returns `undefined` (renders nothing), rather than throwing, warning, or logging.
**Rationale**: `mode` is typed as `ChatMode` (`'inline' | 'three-pane' | 'mobile'`), so TypeScript already rejects any other value at typed call sites — this case is unreachable under the declared type (**route-by-mode**) and only occurs for an untyped JS caller or an explicit type-assertion cast. See the "Invalid mode" edge case for what the untyped-caller path actually does.
**Approved**: pending

