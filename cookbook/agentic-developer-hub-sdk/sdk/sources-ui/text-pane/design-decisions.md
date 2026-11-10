
**Decision**: Use 8pt insets on all edges instead of the 6pt used by Apple's Quick Note and similar scratch fields.
**Rationale**: The wider gutter signals that the pane is a document surface intended for longer reading/editing sessions, not an ephemeral note; see **use-8pt-insets**. The difference is visually intentional and MUST NOT be "fixed" to match other components.
**Approved**: pending

**Decision**: Support only plain text — no rich text, markdown parsing, or styled rendering.
**Rationale**: This constraint simplifies the API, reduces platform-specific rendering complexity, and aligns with the use case of hosting markdown source files, which are plain text; see **use-plain-text-mode**. Styled rendering and markdown preview are the responsibility of parent controllers.
**Approved**: pending

**Decision**: The `text` setter does not fire `onTextChange`.
**Rationale**: This is load-bearing for controllers that re-render from text changes; see **silent-programmatic-set**. A controller that receives `onTextChange`, processes it, and writes the result back via `text =` must not re-enter its own callback, or a feedback loop is inevitable.
**Approved**: pending

**Decision**: Focus is an explicit `focus()` method, not automatic first-responder on initialization.
**Rationale**: This prevents unwanted keyboard display (especially on iOS) and gives the parent window/modal control over focus order; see **support-focus**.
**Approved**: pending

**Decision**: Enable the find bar (`usesFindBar`, `isIncrementalSearchingEnabled`) on macOS only; the iOS variant exposes no find UI.
**Rationale**: This reflects platform UX conventions — the iOS variant relies on the platform's standard text selection and copy flow instead; see **enable-find-bar-macos**. The asymmetry is intentional.
**Approved**: pending

**Decision**: Enable `allowsUndo` on macOS; on iOS, rely on `UITextView`'s default undo behavior rather than adding a custom undo stack.
**Rationale**: The asymmetry reflects platform capabilities and macOS's deeper undo integration. The pane MUST NOT disable the default iOS undo manager; see **allow-undo-macos** and **preserve-default-undo-ios**.
**Approved**: pending

