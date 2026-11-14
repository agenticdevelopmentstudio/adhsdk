
- **Reduce Motion**: Not applicable; CommandPalette does not use transitions or animations that respond to prefers-reduced-motion.
- **Increase Contrast**: Not applicable; CommandPalette does not have a built-in contrast mode; host may apply custom CSS to meet contrast requirements.
- **Differentiate Without Color**: Highlight state is shown by a background-color change (`apt-highlight/15` on the current item, `apt-highlight/10` on hover) and by the `aria-selected` attribute. `aria-selected` is exposed to assistive technology only — it provides no visual cue, so a sighted user who cannot distinguish the highlight color currently has no other way to tell which item is active.

