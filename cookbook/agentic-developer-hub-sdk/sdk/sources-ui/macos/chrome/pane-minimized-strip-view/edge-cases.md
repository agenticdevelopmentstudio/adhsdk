
- **Empty tooltip**: If `tooltip` is empty string, glyph's tooltip is `nil` (no tooltip appears on hover).
- **Very long tooltip**: Tooltip text is set directly on glyph; platform handles wrapping and display.
- **Rapid symbol changes**: Multiple rapid updates to `symbolName` will update the glyph each time; no debouncing is performed.
- **onRestore callback not set**: If `onRestore` is `nil`, tapping restore button has no observable effect (safe no-op).
- **Invalid symbol name**: If provided symbol name cannot be loaded, fallback to `square.dashed` automatically.
- **Theme not observed**: This cannot occur. `observeTheme` applies the current palette synchronously inside its own initializer and then re-applies on every posted theme-change notification, so registration cannot silently fail. If no theme manager is registered, the palette falls back to the built-in default rather than leaving colors unset.
- **View initialization**: Component cannot be initialized from a coder (`.xib`, `.storyboard`); `init(coder:)` is unavailable.

