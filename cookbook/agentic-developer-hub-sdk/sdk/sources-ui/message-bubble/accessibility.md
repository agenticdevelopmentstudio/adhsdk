
- **Role**: Generic container (not a button or interactive control; the component itself is not focusable)
- **Label**: Sender name is provided via a visually-hidden span so screen readers announce who sent the message before reading the text
- **State announcement**: See **failure-announced-on-web** — on Web, the failure reason sits inside a `role="alert"` container and is announced automatically when it appears. On macOS and iOS, delivery-status changes (streaming, failed) are not announced through any live region or accessibility notification; the border and appended text are the only indicators there. Compose and WinUI 3 implementations SHOULD follow the Web pattern (an assertive live region) for parity.
- **Minimum tap target**: Not applicable; this component is a display-only container, not an interactive control. Optional detail indicators provided by the caller SHOULD meet platform tap-target minimums
- **Color dependence**: Sender role (user vs. persona) is distinguished by color; themes that lack sufficient contrast or declare no fill may make the distinction unavailable to color-blind users. The component itself does not provide an alternative, non-color cue (e.g., icon, position) — see **contrast-ratio** in Compliance. Web implementation uses CSS classes that themes can override; Apple implementation checks theme's declared colors and geometry

