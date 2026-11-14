
No test beside the source drives this component. These vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| concealed-001 | not-an-element, no-children | Ask a container for its accessibility element flag and its three children lists | Not an element; each list empty |
| concealed-002 | hit-test-resolves-upward | Hit test the container's accessibility at a point inside it | The result is the nearest unignored ancestor of its superview, never a subview |
| concealed-003 | hit-test-no-superview | Hit test a container with no superview | The result is nothing |
| concealed-004 | is-concealed-self, is-concealed-walks-up | Call `isConcealed(_:)` on the container, on a subview, and on a view two levels deep | True for all three |
| concealed-005 | is-concealed-walks-up | Call `isConcealed(_:)` on a view outside any container | False |
| concealed-006 | marker-protocol, marker-objc-name | Ask the runtime for the protocol named `ATKConcealsContents` and check the container conforms | The protocol is found and the container conforms |
| concealed-007 | revealed-default, capture-conceals-only-while-revealed | Add a fresh container to a window | The window's sharing type is read-only |
| concealed-008 | capture-blank-when-revealed, revealed-updates-window | Set `isRevealed` to true in a window | The window's sharing type is none |
| concealed-009 | capture-restore-when-none | Set `isRevealed` back to false | The window's sharing type is read-only |
| concealed-010 | capture-any-container | Two containers in one window, both revealed, then one concealed | Sharing stays none after the first is concealed, and is read-only after the second is |
| concealed-011 | capture-on-attach | Reveal a container, then add it to a window | The window's sharing type is none |
| concealed-012 | capture-on-detach | Reveal a container in a window, then remove it | The old window's sharing type is read-only |
| concealed-013 | capture-on-detach | Move a revealed container from window A to window B | A is read-only and B is none |
| concealed-014 | capture-search-content-view | Place a revealed container five levels deep in the window | The window's sharing type is none |
| concealed-015 | capture-no-window-no-op | Set `isRevealed` on a container with no window | No error; no window changes |

