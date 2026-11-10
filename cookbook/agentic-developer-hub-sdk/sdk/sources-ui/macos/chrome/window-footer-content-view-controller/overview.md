
A view controller that composes an arbitrary content view controller with a fixed footer bar (`WindowFooterBar`) at the bottom of a window. The footer remains visible and stationary while the content fills the remaining space. This container allows windows to gain a footer without restructuring their content hierarchy—the content view controller is adopted as a child and participates in the responder chain and appearance inheritance as if the window contained it directly.

**Public API**:

| Member | Type | Notes |
|--------|------|-------|
| `init(contentViewController:accessibilityPrefix:)` | `(NSViewController, String) -> WindowFooterContentViewController` | Both parameters are required; neither has a default. |
| `contentViewController` | `NSViewController` (read-only) | What the window is for; adopted as a child in `init`. |
| `footer` | `WindowFooterBar` (read-only) | Exposed directly for footer-specific API (e.g. `trailingAccessories`) beyond `status`. |
| `status` | `String` (computed) | Forwards to `footer.status`. |

