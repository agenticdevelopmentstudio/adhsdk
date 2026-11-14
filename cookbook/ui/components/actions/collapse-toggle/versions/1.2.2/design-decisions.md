
1. **Unicode glyphs for state indication**
   **Decision**: The component uses `»` (RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK, U+00BB) for collapsed and `«` (LEFT-POINTING DOUBLE ANGLE QUOTATION MARK, U+00AB) for expanded — not chevron icons or an image asset — and the glyph is fixed on purpose; the component does not expose a way to swap in different glyphs (arrows, +/-, etc.).
   **Rationale**: A single character needs no icon asset and follows the direction convention of "closed" (pointing away) versus "open" (pointing inward).
   **Approved**: pending

2. **Platform glyph substitution**
   **Decision**: Native platforms other than WinUI 3 substitute a platform-native chevron icon (SF Symbols `chevron.right`/`chevron.left` on Apple platforms, Material Icons chevron left/right on Compose) for the literal `»`/`«` characters; only the WinUI 3 note renders the same U+00BB/U+00AB characters the web source does.
   **Rationale**: Apple and Android platform conventions render this kind of iconography through vector icon assets rather than a typographic character in a text control, so requiring the literal character everywhere would fight the platform's own idioms; WinUI 3's `TextBlock`-based button has no equivalent native chevron icon control, so it keeps the literal character.
   **Approved**: pending

3. **Event forwarding in onToggle**
   **Decision**: The `onToggle` callback receives the full React `MouseEvent` rather than just a boolean.
   **Rationale**: This enables callers to detect Ctrl/⌘-click for hierarchical toggle behavior (noted in the source comment: "apply this toggle to every list"). This trades callback simplicity for power; callers uninterested in modifiers ignore the event parameter.
   **Approved**: pending

4. **aria-expanded always inverted from collapsed**
   **Decision**: The `aria-expanded` attribute is set to `!collapsed` (the opposite of the `collapsed` prop).
   **Rationale**: This ensures the accessible state always reflects the logical expanded state of the controlled region: when `collapsed=true` (user sees the "expand" label and `»` glyph), `aria-expanded=false` signals the region is not yet expanded. This is the correct ARIA mapping.
   **Approved**: pending

5. **No size constraints**
   **Decision**: The button's size is determined entirely by the inherited font size plus the `px-1` padding; the source sets no width, height, or minimum.
   **Rationale**: This is a deliberate trade for placement flexibility — the same control sits in a narrow rail beside TopicDetail and in the theme-editor's column headers — and it moves responsibility for the hit area onto the caller's layout. The Accessibility section records the open question of what minimum that layout has to guarantee.
   **Approved**: pending

6. **Title attribute mirrors aria-label**
   **Decision**: The `title` attribute is set to the same text as `aria-label`.
   **Rationale**: This provides a tooltip for mouse users without duplicating logic; however, it means the tooltip also says "Expand {label}" or "Collapse {label}", which is self-evident to sighted users and potentially redundant.
   **Approved**: pending

7. **Minimum hit area is undecided**
   **Decision**: Whether the toggle button itself must guarantee a minimum 44×44pt/48×48dp hit area, or whether that responsibility stays with the caller's surrounding row layout, is undecided.
   **Rationale**: The source sets no width, height, or minimum size — only `px-1` padding — so at typical rail font sizes the rendered hit area falls under the platform minimum tap-target guidelines (see `#accessibility`). Settling this requires measuring the rendered button at its two call sites (TopicDetail rail, theme-editor column list) against the 44×44pt floor.
   **Approved**: pending

8. **RTL glyph mirroring is undecided**
   **Decision**: Whether the `»`/`«` glyphs should mirror (swap) for right-to-left locales is undecided.
   **Rationale**: The source hardcodes the glyphs as literal, unmirrored characters (see `#localization`); a caller in an RTL locale sees the same visual direction as in LTR, which may read backwards for languages where "closed" and "open" reverse convention.
   **Approved**: pending

