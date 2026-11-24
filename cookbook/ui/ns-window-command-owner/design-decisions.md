
**Decision**: Resolve the owner by walking `parent` to the top instead of stopping at one level.
**Rationale**: The source says a child window's bubbles and menus sit above a page window that is itself a child, so a command may start any number of levels down, and only the top window has panes, notes and a project.
**Approved**: pending

**Decision**: Implement it as a computed property on `NSWindow` in a public extension, not as a helper on each caller.
**Rationale**: Several command paths (key command dispatch, project window lookup, notes, terminal) need the same answer; one definition keeps them from each stopping at the child (separation of concerns).
**Approved**: pending

**Decision**: Return the window itself, not nil, when there is no parent.
**Rationale**: The doc comment defines the owner as "this window, or ... the window it is attached to, at the top of the chain", so the base case needs no optional handling by callers.
**Approved**: pending

