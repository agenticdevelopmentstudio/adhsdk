
**Decision**: The rows are a pure function, `GitMergeLayout.make(document:choices:colours:)`, rebuilt on every choice.
**Rationale**: The alignment, backgrounds and numbering are the whole of the view's logic; as a function of its inputs they are tested without a window, and a conflicted file is small enough that rebuilding is free.
**Approved**: pending

**Decision**: Only ours and theirs are scroll-locked; the result scrolls on its own and is moved by Previous and Next.
**Rationale**: The result's rows are not aligned with the sides (an unchosen conflict is one row, a chosen one the chosen lines), so locking offsets would point the panes at different text.
**Approved**: pending

**Decision**: The view sends the resolved text to its delegate instead of writing it.
**Rationale**: The resolved text is the one file the window writes itself; keeping the write in the model (`writeResolution`, atomic, off the main thread) leaves the view a pure editor of choices and the window's one funnel in charge of side effects.
**Approved**: pending

**Decision**: A Cancel button sends `.cancel`.
**Rationale**: The intent needs a control; without one the only way back to the diff would be selecting another file.
**Approved**: pending
