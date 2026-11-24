
- **Null and empty input**: With no `placementTemplate` the window MUST use the default placement; a template that has been deallocated (the reference is weak) MUST behave as none.
- **Boundary values**: A template window smaller than 400 by 300 points MUST NOT shrink the window below the 400 by 300 minimum, which the window's minimum size enforces. Repeated New Project Window commands MUST keep the cascaded window on screen, which `cascadeTopLeft(from:)` guarantees.
- **Placement timing**: The template MUST be read when the window loads, so the window is placed before it is shown; a window shown at the default and then moved shrinks and regrows in front of the user.
- **Shelf slide in flight**: A swap MUST land the slide before `shelfLayout` is read, so that a half-slid width is not handed over and the slide does not land later on a window already ordered out.
- **Concurrent access**: Not applicable: the controller and its content are `@MainActor` isolated, so all access is serialized on the main actor.
- **Error states**: Not applicable: the controller calls no dependency that can fail; a missing toggle button is skipped in `refreshShelfToggleAppearance()` by a guard.
- **Offline or disconnected state**: Not applicable: the controller performs no network access.
- **Window not yet loaded**: `showWindow(_:)` MUST load the window first when it is not loaded, then show it and refresh the toggle appearance.

