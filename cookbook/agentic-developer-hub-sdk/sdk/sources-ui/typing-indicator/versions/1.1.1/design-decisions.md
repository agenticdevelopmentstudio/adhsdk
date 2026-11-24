
**Decision**: The component provides a three-dot pulse fallback when no status words are configured, rather than requiring every consumer to supply a status vocabulary.
**Rationale**: This preserves backward compatibility with existing consumers and avoids the overhead of the phase machine when custom word vocabularies are not in use. The fallback is the documented default behavior and requires no configuration change.
**Approved**: pending

**Decision**: Status words are drawn from a `ShuffleBag` (draw-without-replacement) rather than chosen at random or in fixed order.
**Rationale**: This ensures each word in the vocabulary is shown once before any word repeats, preventing a four-word persona from showing "thinking thinking zipping thinking" and creating a more balanced rotation. The bag is keyed on the semantic content of the word array, not its object identity, so vocabulary changes mid-turn trigger a rebuild without losing the phase state.
**Approved**: pending

**Decision**: `colorful` mode's random hue draw excludes the ~75°–165° band (greens) and is generated at 85% saturation, 62% lightness.
**Rationale**: Excluding green prevents the active thinking line from rendering in a color typically associated with "done" or "success". The vivid colors are bright enough to distinguish from the grey settled line while remaining readable on typical dark chat backgrounds.
**Approved**: pending

**Decision**: The done/settled line always uses `.thinkingDoneText` and ignores `colorful` and `tint`.
**Rationale**: This creates a visual distinction between the active (possibly vivid/tinted) thinking line and the final settled line, signaling to the user that the turn has completed.
**Approved**: pending

**Decision**: Once the first turn begins, the idle phrase is replaced permanently and never re-shown even if a subsequent turn ends.
**Rationale**: This prevents the idle state from flickering back during rapid turn transitions.
**Approved**: pending

**Decision**: In platform representations where the glyph is a separate visual element (AppKit/macOS), the box containing the glyph has a fixed width that does not change as the animation cycles.
**Rationale**: This prevents the word text from shifting left and right as braille characters of varying widths are displayed. The box width accommodates the widest possible glyph (measured at render time) and centers the glyph within it.
**Approved**: pending

**Decision**: The three-dot rendering path (when no words are configured) does not instantiate or run the phase machine.
**Rationale**: It is a pure visual animation driven by `isTyping`/`status`, keeping memory and CPU overhead minimal for consumers who do not use status vocabularies.
**Approved**: pending

**Decision**: Accessibility announcements are posted only when the phase changes (entering thinking, settling, utterance set), not on every frame or word rotation.
**Rationale**: This provides necessary feedback without overwhelming screen readers with constant updates.
**Approved**: pending

