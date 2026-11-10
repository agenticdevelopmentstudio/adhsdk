
- **Role**: `separator` — the implicit ARIA role of the HTML `<hr>` element; the component adds no explicit `role` attribute.
- **Label requirements**: Not applicable; the `<hr>` element is a semantic separator and requires no additional label or aria-label.
- **Keyboard interaction**: Not applicable; divider is not interactive.
- **Screen reader**: The semantic `<hr>` element is exposed to assistive technology with the `separator` role and is announced as a separator or thematic break.
- **Native platforms**: SwiftUI's `Divider()` and Compose's `HorizontalDivider()` render as non-interactive, decorative elements and are excluded from the accessibility tree by the platform framework's default; AppKit's `NSBox(.separator)` and a UIKit hairline view behave the same way. This matches the non-interactive separator semantics on the web.

