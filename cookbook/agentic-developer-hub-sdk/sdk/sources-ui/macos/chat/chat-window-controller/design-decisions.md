
**Decision**: Hide the title bar (`titleVisibility = .hidden`, `titlebarAppearsTransparent = true`, all three standard buttons hidden) while keeping the window's `title` set.
**Rationale**: The title is retained because it is what the Window menu, Mission Control, and the accessibility tree read; hiding only the bar's furniture balances visual minimalism with platform discoverability.
**Approved**: pending

**Decision**: The window is translucent (`isOpaque = false`, `backgroundColor = .clear`).
**Rationale**: So the theme's own alpha values in the view layer are visible; an opaque window would composite its background first, obscuring theme transparency.
**Approved**: pending

**Decision**: `InlineChatView` is wrapped in a `ChatContentViewController` rather than assigned directly to `contentView`.
**Rationale**: AppKit sizes a direct content view to its minimum unless explicitly constrained; the wrapper's `preferredContentSize` determines the window's initial size instead.
**Approved**: pending

**Decision**: The content view's autoresizing mask is set to `[]` (no flexibility flags — a fixed mask), not left at `NSWindow`'s default flexible mask.
**Rationale**: A flexible mask against `NSThemeFrame` (which auto layout does not manage) leaves the content view's width an unconstrained free variable, so the layout engine settles it at the view's minimum and shrink-wraps the window. A fixed (`[]`) mask makes AppKit derive `width == frame.width` and re-derive it every time the window sets the content frame, so the window still resizes — it just stops shrink-wrapping on the way up.
**Approved**: pending

**Decision**: The `windowBecameKey` observer calls `focusInput()` only when the window's first responder is still the window itself.
**Rationale**: Taking focus unconditionally would clobber an active text selection in the transcript when the window is re-fronted (a status-bar item, ⌘\`, or clicking back from another app).
**Approved**: pending

**Decision**: The frame autosave name is `"<defaultsNamespace>.chatWindowFrame"`, prefixed with the `defaultsNamespace` from `ChatWindowConfiguration`.
**Rationale**: Allows multiple chat windows to maintain independent positions and sizes; each window remembers where it was left without colliding with another window's saved frame.
**Approved**: pending

**Decision**: Both `chatView` and `appearance` are `public` (not `open`) properties.
**Rationale**: Host applications can drive the view directly (e.g., display a placeholder during connection) and access appearance state, without being able to override them from a subclass — see **allow-subclassing**.
**Approved**: pending

**Decision**: The class is declared `open`, and only `showWindow(_:)` is declared `open override`-able.
**Rationale**: This lets hosts subclass to add connection rituals, status-item management, or other application-specific behavior — via a subclass's own initializer that calls `super.init`, new stored properties, or an override of `showWindow(_:)` — without forking the controller or requiring every member to be overridable.
**Approved**: pending

