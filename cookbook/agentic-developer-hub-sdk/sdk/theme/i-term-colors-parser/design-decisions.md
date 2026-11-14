
**Decision**: Foreground, background and all 16 ANSI colors are required and fail fast; cursor and selection fall back to palette-derived values.
**Rationale**: The source comment says cursor and selection are "common but not universal", so partial files still yield a usable theme, while the palette itself is what makes a theme usable.
**Approved**: pending

**Decision**: A theme whose foreground equals its background is rejected with `foregroundMatchesBackground`.
**Rationale**: The doc comment on the error says such a theme renders all text invisible, so it is rejected rather than imported into an unusable state.
**Approved**: pending

**Decision**: Appearance is inferred from the background's relative luminance unless the caller supplies one.
**Rationale**: `.itermcolors` carries no dark/light flag; the source infers it with `isDark` and lets the caller override, including with `.auto`.
**Approved**: pending

**Decision**: The `try?` around cursor and selection discards every error for those two keys, including a present-but-malformed dictionary.
**Rationale**: The fallback is the source's deliberate way to keep partial files importable; it trades a signal about malformed optional colors for leniency. Ports should match it.
**Approved**: pending

**Decision**: Alpha defaults to 1.0 when absent or not a `Double`.
**Rationale**: The source comment says alpha is "frequently omitted", so a missing alpha is treated as opaque.
**Approved**: pending

**Decision**: Plist decode errors and file read errors are not wrapped in `ITermColorsParseError`.
**Rationale**: The doc comment promises `ITermColorsParseError` for malformed structure and missing colors; Foundation's errors for undecodable bytes and unreadable files pass through unchanged, so callers must catch both kinds.
**Approved**: pending

