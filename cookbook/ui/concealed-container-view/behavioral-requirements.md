
### Accessibility

- **not-an-element**: The container MUST NOT be an accessibility element.
- **no-children**: The container MUST report no accessibility children, no children in navigation order and no visible children.
- **hit-test-resolves-upward**: An accessibility hit test landing on the container MUST resolve to the nearest unignored accessibility ancestor of its superview, and never to anything inside it.
- **hit-test-no-superview**: An accessibility hit test on a container that has no superview MUST resolve to nothing.
- **inner-views-not-elements**: A view placed inside the container SHOULD NOT be an accessibility element either, because a hit test could still land on it.

### Concealment check

- **is-concealed-static**: A static `isConcealed(_:)` check MUST be offered, taking a view.
- **is-concealed-walks-up**: `isConcealed(_:)` MUST return true when the view is a concealed container or any ancestor of it is one, and false otherwise.
- **is-concealed-self**: `isConcealed(_:)` MUST return true for a concealed container itself.
- **marker-protocol**: The container MUST conform to a marker protocol with no requirements, for frameworks that cannot import this one.
- **marker-objc-name**: The marker protocol MUST be exposed to the Objective-C runtime under the fixed name `ATKConcealsContents`.
- **marker-name-fixed**: The marker protocol's Objective-C name MUST NOT be changed, because a framework that looks it up by name breaks silently if it is.

### Revealing

- **revealed-default**: A container MUST start not revealed.
- **revealed-owner-set**: The owner MUST set `isRevealed` to true when its privacy screen comes down and back to false when it goes back up.
- **revealed-updates-window**: Changing `isRevealed` MUST re-evaluate the screen-capture state of the container's window.

### Screen capture

- **capture-blank-when-revealed**: A window that has at least one revealed concealed container MUST have its sharing type set to none.
- **capture-restore-when-none**: A window with no revealed concealed container MUST have its sharing type set to read-only.
- **capture-any-container**: A window with several concealed containers MUST be blanked while any one of them is revealed, and restored only when none is.
- **capture-on-attach**: Adding the container to a window MUST re-evaluate that window's sharing type.
- **capture-on-detach**: Removing the container from a window, or moving it to another, MUST re-evaluate the old window's sharing type with the container's own claim left out, even if it is still revealed.
- **capture-search-content-view**: The re-evaluation MUST search the window's content view tree, finding a container no matter how deep it sits, and MUST NOT descend into a concealed container once found.
- **capture-no-window-no-op**: With no window, or a window without a content view, re-evaluation MUST do nothing.
- **capture-conceals-only-while-revealed**: A container that is not revealed MUST NOT blank its window.

### Lifetime and isolation

- **open-for-subclass**: The container MUST be open for subclassing, with its accessibility and window-move hooks overridable.
- **ui-thread-confined**: The container MUST be used on the main thread only; the hit-test override MUST assume the main thread because the platform asks on it.

