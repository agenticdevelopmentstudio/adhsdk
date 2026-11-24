
- **Layout mechanism**: The component applies no inline styling itself; the crop's margin, direction, and distance are defined by the `lp-bleed` and `lp-bleed--{side}` CSS classes, as named in **bleed-offset**, **bleed-breakpoint** and **bleed-min-width**: at `62rem` and wider the `side` edge gets a negative margin of `var(--lp-bleed, clamp(2.5rem, 10vw, 9rem))`, and below that nothing changes.
- **Mechanism, not magnitude**: Per the **Margin over transform** design decision, the crop is achieved with `margin`, not `transform`, so the neighboring column surrenders space. The component itself only applies the class names; the margin distance and the narrow-width behavior come from the stylesheet requirements above.
- **Clipping dependency**: The overhang needs a clipping ancestor — see the **Missing clipping parent** edge case and the `Band` ingredient ([adhsdk.ingredient.landing.flow.band](cookbook:e0b59d60-0a56-4bf4-85cb-fb0e58170f8e)).

