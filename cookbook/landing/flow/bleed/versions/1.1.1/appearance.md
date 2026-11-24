
- **Layout mechanism**: The component applies no inline styling itself; the crop's margin, direction, and distance are entirely defined by the `lp-bleed` and `lp-bleed--{side}` CSS classes (declared in the landing package's stylesheet, not in `Bleed.tsx`).
- **Mechanism, not magnitude**: Per the **Margin over transform** design decision, the crop is achieved with `margin`, not `transform`, so the neighboring column surrenders space. The component's own contract stops at applying the class names; the exact margin distance and any narrow-width behavior belong to those CSS classes, not to this component.
- **Clipping dependency**: The overhang only reads as "cropped" rather than "widening the page" when rendered inside an ancestor with `overflow-x: clip` — see the **Missing clipping parent** edge case and the `Band` ingredient ([adhsdk.ingredient.landing.flow.band](cookbook:e0b59d60-0a56-4bf4-85cb-fb0e58170f8e)).

