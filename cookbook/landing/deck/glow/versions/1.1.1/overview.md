
The Glow component is a purely decorative visual element that renders a styled `<div>` with a glow effect. It is excluded from accessibility trees (`aria-hidden="true"`) and serves only as visual enhancement. Visual appearance is entirely managed through CSS classes (base class `lp-glow` plus optional additional classes). When nested inside a centered screen (the hero), the glow's vertical offset is derived from the hero's own `--lp-hero-pad-top` and `--lp-hero-pad-bottom` custom properties (see the hero ingredient) rather than a hardcoded constant.

