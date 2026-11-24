
- **returns-self-without-parent**: When the window has no parent window,
  `commandOwner` MUST return that same window.
- **returns-parent-of-child**: When the window has a parent window and that
  parent has none, `commandOwner` MUST return the parent.
- **walks-to-top-of-chain**: When the window's parent itself has a parent,
  `commandOwner` MUST keep following the parent link and MUST return the
  window at the top of the chain, whatever its depth.
- **identity-not-copy**: `commandOwner` MUST return the existing window
  object, not a copy or a proxy.
- **read-only**: `commandOwner` MUST be a computed, get-only property; it
  MUST NOT store, cache or change any state on any window.
- **reads-live-parent**: `commandOwner` MUST read the parent link on every
  access, so that attaching or detaching a child window changes the answer on
  the next read.
- **non-optional**: `commandOwner` MUST always return a window; it MUST NOT
  return nil, because the window itself is the base case.

