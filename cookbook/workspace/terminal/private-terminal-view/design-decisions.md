
**Decision**: Conceal output before the terminal engine parses it, not when it is drawn.
**Rationale**: The source says concealing before the parser means the buffer, scrollback, title and reported directory all hold the alias, so nothing that reads the terminal afterwards can find the real text.
**Approved**: pending

**Decision**: Hold input and output that could still become a word until it diverges or completes.
**Rationale**: The source says sending half an alias and the rest later would send the alias itself, so a possible partial match is held rather than passed on.
**Approved**: pending

**Decision**: Flush held output after 0.15 seconds of quiet, but never flush held input on a timer.
**Rationale**: The source flushes output so a prompt ending in a word's prefix still appears; input has no timer in the source, so held input waits for the next keystroke or a change of words. This is the actual behavior, not an idealized one.
**Approved**: pending

**Decision**: Use a target-and-selector timer instead of a block timer.
**Rationale**: The source says the block is `@Sendable` and handing the view to it is a region-isolation error; the timer holds the view for at most the quiet interval.
**Approved**: pending

**Decision**: Flush both streams under the old words before swapping in new ones.
**Rationale**: The source says replacing the words flushes what each stream was holding under the old words so nothing is lost.
**Approved**: pending

**Decision**: Make the view invisible to assistive technology.
**Rationale**: The source says nothing in the view is an accessibility element and a screen reader sees an empty space; this keeps real text out of the accessibility tree, at the cost of removing the terminal from screen-reader users, which is the open question on `screen-reader-alternative`.
**Approved**: pending

**Decision**: Subclass the themed terminal view rather than wrap it.
**Rationale**: The source overrides the engine's own send and data-received entry points, which only a subclass can reach, and keeps the themed view's caret behavior unchanged.
**Approved**: pending

