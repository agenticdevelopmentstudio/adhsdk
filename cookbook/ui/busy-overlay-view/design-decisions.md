
**Decision**: The overlay is removed only by its owner calling `hide()`, never by a press or a key.
**Rationale**: What it covers is about to be redrawn; a click landing on the old layout would act on a row that is moving.
**Approved**: pending

**Decision**: The overlay fades with the Dismissible Overlay View's `fadeDuration` (0.2 seconds) rather than its own constant.
**Rationale**: The two read as the same kind of surface, and one duration keeps them in step.
**Approved**: pending

**Decision**: The overlay is added above every sibling of the host, titlebar accessories included.
**Rationale**: Nothing beneath may be reachable; a lower z-position would leave some control clickable.
**Approved**: pending

**Decision**: `show` during a fade-out takes the fade back instead of waiting for removal, tracked by an internal hiding flag that the fade-out completion checks.
**Rationale**: A caller that finishes one piece of work and starts another must not see the overlay flicker away and return, or be left with a removed overlay.
**Approved**: pending

**Decision**: Input is swallowed by answering every hit test inside the frame and giving mouse-down, right-mouse-down, other-mouse-down and scroll-wheel handlers empty bodies, and by accepting the first mouse event.
**Rationale**: A click on an inactive window would otherwise reach the control beneath; the empty handlers stop the event from travelling up the responder chain.
**Approved**: pending

**Decision**: Hit tests answer nothing once the overlay is hidden or at opacity 0.
**Rationale**: The guard on hidden and zero opacity keeps a transparent overlay from taking a press. Because the fade is animated through the animator, which sets the opacity value at once, this also means a fading-out overlay stops swallowing input as soon as `hide()` is called.
**Approved**: pending

**Decision**: Key events are not intercepted, and no accessibility announcement or reduced-motion path exists.
**Rationale**: The source implements only pointer swallowing; the open questions on Announce state changes and Reduce Motion record what a reviewer should settle.
**Approved**: pending

