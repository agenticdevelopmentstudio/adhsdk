
`PressableButton` is the `"use client"` interactivity layer for the shared
`Button` component. It wraps the Base UI `Button` primitive and tracks a
pointer-driven "held" and "pressed" state that CSS `:active` cannot express —
in particular, the case where the pointer is dragged out of the button while
still held, and dragged back in before release. It reflects the pressed state
via a `data-pressed` attribute for the consuming styles to key off of, and it
composes with any pointer handlers the caller supplies rather than replacing
them. It lives in its own module, separate from the plain `button.tsx` module
that computes the visual variant classes, so that module can stay free of a
`"use client"` directive and remain callable from server components. See
[adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) for the composed component,
its visual variants, and its accessibility surface.

