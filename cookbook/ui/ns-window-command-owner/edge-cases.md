
- **Window with no parent**: the window itself is returned (MUST); a top-level
  window is its own command owner.
- **Deep chain**: a child of a child of a window resolves to the outermost
  window (MUST), because the source loops until the parent is nil.
- **Parent changes between reads**: the answer follows the current parent
  link (MUST); nothing is cached, so a window detached from its parent answers
  with itself on the next read.
- **Missing window (nil)**: not handled here, because the property lives on a
  window that exists. The callers handle the absent key window by optional
  chaining before reading it (`NSApp.keyWindow?.commandOwner`).
- **Cyclic parent chain**: the loop has no cycle guard, so a chain that led back
  to itself would not end. The source performs no check for it.
- **Concurrent access**: `NSWindow` is main-thread-only AppKit and the property
  does no locking; the callers in the source read it on the main thread: `ProjectWindowManager`,
  `NotesCoordinator` and `TerminalCoordinator` are `@MainActor`, and
  `KeyCommandRegistry.commandWindow` reads it from AppKit key handling.
- **Error states and offline state**: not applicable — the property raises
  no errors, does no I/O and has no dependency that could be unavailable.

