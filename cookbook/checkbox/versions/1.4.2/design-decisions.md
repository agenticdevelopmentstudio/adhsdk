
1. **Decision**: Provide two visual modes via the `appearance` prop — switch mode sets `role="switch"` on the wrapper's input; check mode uses the implicit checkbox role.
**Rationale**: Aligns with platform conventions (Apple HIG distinguishes toggles from checkboxes; Material Design 3 treats Checkbox and Switch as separate controls) and gives assistive technology the correct semantics for each mode.
**Approved**: pending

2. **Decision**: Default the wrapper's `appearance` prop to `'switch'`.
**Rationale**: The wrapper's default parameter, `appearance = 'switch'` (`Checkbox.tsx`), makes toggle-style rendering the out-of-the-box behavior for this form-field component.
**Approved**: pending

3. **Decision**: Type `value` and `onChange` as required (non-optional) members of `CheckboxProps` on the wrapper.
**Rationale**: Enforces controlled-only usage at the form-field layer and prevents accidental uncontrolled use. The underlying primitive (`@base-ui/react/checkbox`'s `Checkbox.Root`) separately supports both controlled and uncontrolled modes, which is why `controlled-and-uncontrolled` (see Behavioral Requirements) is scoped to the primitive only.
**Approved**: pending

4. **Decision**: Rely on `htmlFor` label association and the native `disabled` attribute for accessibility; the source applies no `aria-label` or `aria-describedby`.
**Rationale**: These two source-visible mechanisms cover role and disabled-state announcement for free; the hint-to-input link (`aria-describedby`) is not automatic, which is why it is captured separately as the `hint-description-association` SHOULD requirement rather than assumed here.
**Approved**: pending

5. **Decision**: Size the checkmark glyph at 12px (`size-3`) with a 3px stroke inside the 16px container.
**Rationale**: Smaller than the container to avoid visual clipping; the heavier stroke keeps the glyph legible at that small size.
**Approved**: pending

6. **Decision**: Animate only `transition-colors` on the primitive; no geometry or opacity motion.
**Rationale**: Because no motion exists in the source, there is nothing to suppress under Reduce Motion, so this component takes no Reduce-Motion deviation.
**Approved**: pending

7. **Decision**: Signal the checked state through two independent channels — the `apt-gold` fill and the `Check` glyph.
**Rationale**: The glyph is what makes `checked-without-color` testable; dropping it and keeping only the color fill would regress Differentiate Without Color.
**Approved**: pending

