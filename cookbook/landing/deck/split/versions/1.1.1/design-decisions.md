
**Decision**: All styling and layout values — the breakpoint (`62rem`/992px), the column template (`minmax(0, 5fr) minmax(0, 6fr)`), and the gap (`2rem` stacked, `3rem` two-column) — live in CSS (`packages/web/packages/landing/src/css/base.css`), not in the component. The component only renders children with the merged `lp-split`/`className` classes.
**Rationale**: Keeps the component stateless and its responsibility narrow; centralizing the values in one CSS file keeps this spec from drifting out of sync with the actual breakpoint. Platform ports should mirror this: use a native declarative layout primitive (SwiftUI `ViewThatFits`/`AnyLayout`, Compose `BoxWithConstraints`, a WinUI `Grid` with `AdaptiveTrigger`) driven by measured width or size class, rather than an imperative resize/orientation event handler.
**Approved**: pending

