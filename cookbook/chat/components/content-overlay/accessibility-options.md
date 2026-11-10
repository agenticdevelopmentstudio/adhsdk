
The component does not directly respond to system-level accessibility options. Increase Contrast and Differentiate Without Color are not addressed in the traced stylesheet. Reduce Motion is also not addressed: the root's `opacity` transition (see Appearance → Transitions) runs unconditionally, with no `prefers-reduced-motion` media query gating it.

