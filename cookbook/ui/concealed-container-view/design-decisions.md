
**Decision**: Accessibility concealment works by being a non-element with no children, not by hiding each descendant.
**Rationale**: Per the source comment, the subtree under the container then simply does not exist to an accessibility client, for VoiceOver and programmatic walks alike, with no per-view bookkeeping.
**Approved**: pending

**Decision**: A hit test resolves to the nearest unignored ancestor of the superview.
**Rationale**: Per the source comment, a hit test landing inside the container must resolve to the element above it, so nothing below is ever named.
**Approved**: pending

**Decision**: Screen capture is blanked only while a container is revealed.
**Rationale**: Per the source comment, the owner reveals the contents when its privacy screen comes down; only then is anything readable on screen to protect, and the window is restored when no container in it is revealed any longer. The owner's privacy screen covers the contents whenever they are not revealed (see `capture-while-concealed`).
**Approved**: pending

**Decision**: The window's blanking is derived by searching the content view for revealed containers, not by a counter.
**Rationale**: The state is recomputed from the view tree on each change, so a container leaving or arriving cannot leave a count out of step; the cost is a tree walk per change.
**Approved**: pending

**Decision**: Scripting frameworks find a concealed view through a marker protocol under a fixed Objective-C name.
**Rationale**: Per the source comment, a framework beneath this one cannot import it, so it asks the runtime for `ATKConcealsContents` and stops at any conforming view; renaming it would break them silently, so the name is fixed.
**Approved**: pending

