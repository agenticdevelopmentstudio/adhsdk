
- **Size**
  **Decision**: RadioGroupItem renders at 16×16px (Tailwind `size-4`).
  **Rationale**: Matches the toolkit's compact control sizing; this is below the WCAG 2.5.8 (AA) minimum target size of 24×24 CSS pixels, so consumers MUST ensure the associated `<label>` (or an equivalent wrapping hit area) extends the clickable region to at least 24×24px — a click on a label associated through Base UI's wiring is how a pointer user reaches the control.
  **Approved**: pending

- **Color transitions**
  **Decision**: `transition-colors` is applied to all state changes (checked and focused; disabled has no color change).
  **Rationale**: Provides visual feedback without jarring state shifts, following modern UI conventions. The transition is a brief color fade only, with no transform or motion, so it is treated as exempt from Reduce Motion policies rather than something the component must gate on `prefers-reduced-motion`; a consuming design system that wants zero transition can override with `transition-none`.
  **Approved**: pending

- **Focus ring**
  **Decision**: The focus-visible state uses a 2px ring (`ring-2`) at 25% opacity of `apt-gold`, in addition to the 1px `apt-gold` border.
  **Rationale**: Provides sufficient visibility without overwhelming the control, balancing accessibility with design aesthetic.
  **Approved**: pending

- **Disabled state**
  **Decision**: `RadioGroupItem` carries `disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50`. Because the root is now a native `<button type="button">`, a disabled item carries the native `disabled` attribute (alongside `aria-disabled="true"` and `data-disabled`), so these utilities match and the item is visibly dimmed; selection is also blocked by Base UI's internal pointer/keyboard guards.
  **Rationale**: This is the wrapper's styling, shared with the other form controls; the native-button root (see Native button root) is what makes it take effect.
  **Approved**: pending

- **Native button root**
  **Decision**: `RadioPrimitive.Root` renders a native `<button type="button">` (`nativeButton`, `render={<button type="button" />}`) instead of Base UI's default `<span role="radio">`.
  **Rationale**: Base UI 1.5's span radio swallows Space inside a group: its composite Space handler prevents the keydown before RadioRoot's `onClick`, which bails on `defaultPrevented`, so Space never selected. A native button takes the `click()` path, so Space selects (radio-007), and it also lets the `disabled:` utilities match.
  **Approved**: pending

