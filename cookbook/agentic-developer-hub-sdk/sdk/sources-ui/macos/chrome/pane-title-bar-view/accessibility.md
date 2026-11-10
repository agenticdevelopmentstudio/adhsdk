
- **Identifier**: The title label carries the accessibility identifier `pane.title` (via `accessibilityID`), used to locate the view in UI tests and automation — it is an identifier, not the announced label.
- **Label**: `NSTextField`'s accessibility label derives from `stringValue`, which always holds the full, untruncated title text. Visual middle-truncation (`lineBreakMode = .byTruncatingMiddle`) affects only the rendered glyphs, not `stringValue`, so VoiceOver announces the complete title even when the on-screen text is truncated.
- **Role**: The component itself is a container; child elements (title label, controls, gear) provide their own accessibility semantics.
- **Assistive technology**: The component does not announce state changes; it is a static chrome element.

