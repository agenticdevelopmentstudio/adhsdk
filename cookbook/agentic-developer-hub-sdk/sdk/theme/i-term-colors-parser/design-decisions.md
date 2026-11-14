
**Decision**: Foreground, background and all 16 ANSI colors are required and fail fast; cursor and selection fall back to palette-derived values.
**Rationale**: Cursor and selection each have a safe palette-derived substitute (the foreground, and a background-to-foreground blend), so a file without them still yields a usable theme. The foreground, background and ANSI colors have no substitute, and the palette is what makes a theme usable. The doc comment on `parse` describes cursor and selection as "common but not universal"; that is the source's claim and no external sample is cited here.
**Approved**: pending

**Decision**: A theme whose foreground equals its background is rejected with `foregroundMatchesBackground`.
**Rationale**: Text drawn in the background color is invisible, so such a theme is rejected rather than imported into an unusable state. This follows from the colors being identical; the doc comment on `ITermColorsParseError.foregroundMatchesBackground` makes the same point.
**Approved**: pending

**Decision**: Appearance is inferred from the background's relative luminance unless the caller supplies one.
**Rationale**: `.itermcolors` carries no dark/light flag; the source infers it with `isDark` and lets the caller override, including with `.auto`.
**Approved**: pending

**Decision**: The `try?` around cursor and selection discards every error for those two keys, including a present-but-malformed dictionary.
**Rationale**: The fallback is the source's deliberate way to keep partial files importable; it trades a signal about malformed optional colors for leniency. Ports should match it.
**Approved**: pending

**Decision**: Alpha defaults to 1.0 when absent or not a `Double`.
**Rationale**: A color with no alpha is conventionally opaque, so an absent alpha is treated as `1.0`; the comment on the alpha read in `ITermColorsParser.swift` says alpha is "frequently omitted". A present but non-numeric alpha also becomes `1.0`, unlike the other components, which throw.
**Approved**: pending

**Decision**: Plist decode errors and file read errors are not wrapped in `ITermColorsParseError`.
**Rationale**: The doc comment promises `ITermColorsParseError` for malformed structure and missing colors; Foundation's errors for undecodable bytes and unreadable files pass through unchanged, so callers must catch both kinds.
**Approved**: pending

