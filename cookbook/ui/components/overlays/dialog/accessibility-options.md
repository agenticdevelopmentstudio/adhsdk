
- **Reduce Motion**: Not applicable — `dialog.tsx` applies no open/close transition or animation classes to the backdrop or the popup; the only `transition-colors` class is on the close button's hover text color, which is not motion.
- **Differentiate Without Color**: Not applicable — no state is conveyed by color alone.
- **Increase Contrast**: Inherits text color contrast from the `apt-*` token family; the actual contrast values live outside this file (see Compliance's `contrast-ratio` status).
- **Reduce Transparency**: Not addressed by the current implementation — the backdrop always renders at `bg-black/30` with `backdrop-blur-sm` regardless of this system preference.

