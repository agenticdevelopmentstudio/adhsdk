
**Decision**: Adopt `contentViewController` as a child view controller rather than simply adding its view.
**Rationale**: This preserves the content controller's participation in the responder chain and appearance propagation, letting it behave as if the window contained it directly. It is a separation of concerns: the window does not know about the footer; the footer is added transparently.
**Approved**: pending

**Decision**: Require the `accessibilityPrefix` parameter, with no default.
**Rationale**: Multiple windows with footers in the same app would otherwise share accessibility identifiers, breaking UI testing and other identifier-based automation. Explicit naming requires developers to think about uniqueness.
**Approved**: pending

**Decision**: Forbid initialization from `NSCoder`.
**Rationale**: The component cannot be configured via Interface Builder—it requires a content view controller reference at runtime, not at build time. A fatal error is more transparent than a silent failure.
**Approved**: pending

**Decision**: Expose `status` on the container itself, forwarding to `footer.status`, while also keeping `footer` public.
**Rationale**: `status` is the single most common thing a host sets, so forwarding it lets callers hold one reference instead of reaching through two layers. `footer` stays public too, because `WindowFooterBar` has its own API surface this container doesn't forward—for example `trailingAccessories`—so callers needing that still have a way in without the container growing a forwarding property for every future addition to `WindowFooterBar`.
**Approved**: pending

