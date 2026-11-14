
1. **Decision**: Use the native browser HTML5 `<input type="range">` element rather than a custom-built slider.
**Rationale**: This provides built-in accessibility (semantic role and keyboard support) and cross-browser consistency, but limits visual customization to CSS.
**Approved**: pending

2. **Decision**: Implement the slider as a controlled component — its value is managed entirely by the parent via the `value` prop and `onChange` callback.
**Rationale**: Aligns with React's unidirectional data flow and lets the parent compose validation, formatting, or multi-step workflows.
**Approved**: pending

3. **Decision**: Make the label optional, associating it to the input via `htmlFor` only when provided.
**Rationale**: Supports both labeled and unlabeled use cases while keeping the association correct whenever a label is present; see the label association note under Accessibility for the accessible-name gap this leaves when `label` is omitted.
**Approved**: pending

4. **Decision**: Support the caption as either a static node or a function of the current value.
**Rationale**: Lets the caller display the current value or other state-dependent information without maintaining a separate derived state.
**Approved**: pending

5. **Decision**: Default `min` to `0`, `max` to `100`, and `step` to `1`.
**Rationale**: Provides a useful out-of-the-box integer range (0–100) that covers common cases and can be overridden when a different range is needed.
**Approved**: pending

6. **Decision**: Delegate all visual styling — color, spacing, dimensions, shadows — to CSS classes rather than hard-coding it in the component.
**Rationale**: Keeps styling consistent and centrally managed across the application.
**Approved**: pending

7. **Decision**: Export `Slider` as the canonical component name; keep `CaptionedSlider` as an alias of the same function (`export const CaptionedSlider = Slider`).
**Rationale**: Preserves backward compatibility for existing imports of `CaptionedSlider` while giving new code a single, unambiguous name to import.
**Approved**: pending

