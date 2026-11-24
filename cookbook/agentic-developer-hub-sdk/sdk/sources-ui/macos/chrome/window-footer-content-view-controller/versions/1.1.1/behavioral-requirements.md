
- **content-child**: The container MUST adopt the provided `contentViewController` as a child view controller, ensuring it participates in the responder chain and inherits appearance settings from the parent window.
- **stacked-layout**: The container MUST position the content view controller's view above the `WindowFooterBar` in the view hierarchy, with the footer anchored to the bottom.
- **content-space-fill**: The content view controller's view MUST expand to fill all available space in the container except the space occupied by the footer bar.
- **footer-bottom-position**: The `WindowFooterBar` MUST be anchored to the bottom edge of the container and stretch to the full width.
- **status-forwarding**: The `status` property MUST forward all getter and setter calls to the footer's `status` property, allowing callers to set the footer's leading status text through a single reference.
- **accessibility-prefix-required**: The initializer MUST require an `accessibilityPrefix` parameter (no default) to namespace the footer's accessibility controls, ensuring that multiple windows with footers do not share accessibility identifiers.
- **nscoder-init-unsupported**: Initialization from an `NSCoder` (e.g., from Interface Builder) MUST NOT be supported and MUST raise a fatal error if attempted.

