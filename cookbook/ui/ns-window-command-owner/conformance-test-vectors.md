
The source has no tests beside it; every vector is derived from the property's
body and doc comment.

| ID | Requirements | Input | Expected |
|---|---|---|---|
| command-owner-001 | returns-self-without-parent | window `A` with no parent | `A.commandOwner` is `A` |
| command-owner-002 | returns-parent-of-child | child window `C` attached to window `A` | `C.commandOwner` is `A` |
| command-owner-003 | walks-to-top-of-chain | window `A` with child `B`, and `B` with child `C` | `C.commandOwner` is `A` and `B.commandOwner` is `A` |
| command-owner-004 | returns-self-without-parent, identity-not-copy | top-level window `A` | `A.commandOwner === A` (same object) |
| command-owner-005 | reads-live-parent | `C` is a child of `A`, then `A.removeChildWindow(C)` | `C.commandOwner` is `A` before the removal and `C` after it |
| command-owner-006 | reads-live-parent | standalone `C`, then `A.addChildWindow(C, ordered: .above)` | `C.commandOwner` is `C` before the attach and `A` after it |
| command-owner-007 | returns-parent-of-child | key window is a child page window over a pane; `KeyCommandRegistry.commandWindow` evaluates `(dispatchingEvent?.window ?? NSApp.keyWindow)?.commandOwner` | the result is the project window, not the page window |

