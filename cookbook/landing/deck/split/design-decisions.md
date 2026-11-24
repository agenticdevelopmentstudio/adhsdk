
**Decision**: All styling and layout values (breakpoint, column template and gap, stated in Appearance) live in CSS, not in the component. The component only renders children with the merged `lp-split`/`className` classes.
**Rationale**: Keeps the component stateless and its responsibility narrow; centralizing the values in one CSS file, and stating them once in Appearance, keeps this spec from drifting out of sync with the actual breakpoint. Platform ports should mirror this: use a native declarative layout primitive (SwiftUI `AnyLayout`, including inside an `NSHostingView` on macOS; Compose `BoxWithConstraints`; a WinUI `Grid` with `AdaptiveTrigger`) driven by measured width or size class, rather than an imperative resize/orientation event handler.
**Approved**: pending

