
- **Size**
  **Decision**: RadioGroupItem renders at 16×16px (Tailwind `size-4`).
  **Rationale**: Matches the toolkit's compact control sizing; this is below the WCAG 2.5.8 (AA) minimum target size of 24×24 CSS pixels, so consumers MUST ensure the associated `<label>` (or an equivalent wrapping hit area) extends the clickable region to at least 24×24px — Base UI's radio role allows selecting via a click on the associated label.
  **Approved**: pending

- **Color transitions**
  **Decision**: `transition-colors` is applied to all state changes (checked, focused, disabled).
  **Rationale**: Provides visual feedback without jarring state shifts, following modern UI conventions. The transition is a brief color fade only, with no transform or motion, so it is treated as exempt from Reduce Motion policies rather than something the component must gate on `prefers-reduced-motion`; a consuming design system that wants zero transition can override with `transition-none`.
  **Approved**: pending

- **Focus ring**
  **Decision**: The focus-visible state uses a 2px ring (`ring-2`) at 25% opacity of `apt-gold`, in addition to the 1px `apt-gold` border.
  **Rationale**: Provides sufficient visibility without overwhelming the control, balancing accessibility with design aesthetic.
  **Approved**: pending

- **Disabled state**
  **Decision**: `RadioGroupItem` carries `disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50`, but Base UI's `RadioPrimitive.Root` (`nativeButton=false`) renders as a `<span role="radio">`, which never matches the native `:disabled` selector these utilities target, so no visual dimming occurs; the disabled state is instead exposed via `aria-disabled="true"`, `data-disabled`, and `tabindex="-1"`, and selection is still blocked by Base UI's internal pointer/keyboard guards rather than by CSS.
  **Rationale**: This is the wrapper's existing styling, carried over unchanged from the other form controls; it is dead code for Radio's actual DOM shape, so consumers needing a visible disabled treatment MUST add a `data-disabled:` (or `aria-disabled:`) variant themselves.
  **Approved**: pending

