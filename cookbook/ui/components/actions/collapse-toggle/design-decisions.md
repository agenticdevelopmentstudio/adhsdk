
1. **Unicode glyphs for state indication**
   **Decision**: The component uses `»` (RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK, U+00BB) for collapsed and `«` (LEFT-POINTING DOUBLE ANGLE QUOTATION MARK, U+00AB) for expanded — not chevron icons or an image asset — and the glyph is fixed on purpose; the component does not expose a way to swap in different glyphs (arrows, +/-, etc.).
   **Rationale**: A single character needs no icon asset and follows the convention that the glyph points the direction the region's edge will move when activated: for a rail anchored at the left, `»` (collapsed) points right to expand and `«` (expanded) points left to collapse. Implementations on RTL or native platforms should derive the glyph from that direction of motion, not copy the web glyphs.
   **Approved**: pending

2. **Platform glyph substitution**
   **Decision**: Native platforms other than WinUI 3 substitute a platform-native chevron icon (SF Symbols `chevron.right`/`chevron.left` on Apple platforms, Material Icons chevron left/right on Compose) for the literal `»`/`«` characters; only the WinUI 3 note renders the same U+00BB/U+00AB characters the web source does.
   **Rationale**: Apple and Android platform conventions render this kind of iconography through vector icon assets rather than a typographic character in a text control, so requiring the literal character everywhere would fight the platform's own idioms; WinUI 3's `TextBlock`-based button has no equivalent native chevron icon control, so it keeps the literal character.
   **Approved**: pending

3. **Event forwarding in onToggle**
   **Decision**: The `onToggle` callback receives the full React `MouseEvent` rather than just a boolean.
   **Rationale**: This enables callers to detect Ctrl/⌘-click for hierarchical toggle behavior (noted in the source comment: "apply this toggle to every list"). This trades callback simplicity for power; callers uninterested in modifiers ignore the event parameter.
   **Approved**: pending

4. **Title attribute mirrors aria-label**
   **Decision**: The `title` attribute is set to the same text as `aria-label`.
   **Rationale**: This gives mouse users a tooltip without a second string to maintain. The redundancy is accepted: the tooltip repeats the accessible name, which sighted users find self-evident, but one source for both keeps them from drifting apart.
   **Approved**: pending

6. **Minimum hit area is undecided**
   **Decision**: The button sets no width, height or minimum size, only inherited font size plus `px-1` padding. Whether the toggle must guarantee a minimum 44×44pt/48×48dp hit area itself, or leave that to the caller's surrounding layout, is undecided.
   **Rationale**: Leaving the size open gives placement flexibility: the same control sits in a narrow rail and in column headers, and the layout then owns the hit area. The cost is that at typical rail font sizes the rendered hit area falls under platform tap-target guidelines (see `#accessibility`). Settling this requires measuring the rendered button in each placement against the 44×44pt floor.
   **Approved**: pending

7. **RTL glyph mirroring is undecided**
   **Decision**: Whether the `»`/`«` glyphs should mirror (swap) for right-to-left locales is undecided.
   **Rationale**: The source hardcodes the glyphs as literal, unmirrored characters (see `#localization`); a caller in an RTL locale sees the same visual direction as in LTR, which may read backwards for languages where "closed" and "open" reverse convention.
   **Approved**: pending

