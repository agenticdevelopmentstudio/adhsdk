
- **Reduce Motion**: Not disabled by the component. The Tailwind `transition-colors` class fades the border color on selection and hover; it involves no movement or keyframes, and the source does not turn it off under `prefers-reduced-motion`.
- **Increase Contrast**: Not applicable. Component uses design tokens from the `apt-*` system; contrast requirements are managed at the token level, not within this component.
- **Differentiate Without Color**: Not met for selection. The selected state is conveyed by border color alone, with no icon, fill or thicker border; see the Accessibility section.

