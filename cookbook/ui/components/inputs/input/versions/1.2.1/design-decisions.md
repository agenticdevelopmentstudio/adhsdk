
**Decision**: Destructure `autoComplete` out of the forwarded props before spreading the remaining props onto the input.
**Rationale**: The component sets `autoComplete` explicitly — either the caller's token or the value `noAutofillPropsFor()` computes — before the trailing `{...props}` spread. If `autoComplete` were left inside `props`, that trailing spread would re-apply whatever value the caller passed and silently erase the computed value. Destructuring removes it from the tail spread entirely, so the earlier, correctly computed value always wins; this holds identically whether the caller omitted `autoComplete` or passed it explicitly as `undefined`, since both reach the same code path with the same result once destructured.
**Approved**: pending

**Decision**: Share a single `fieldShellClass` constant for the field-shape styling (border, rounded corners, background) across sibling field controls (Textarea, Select, and other field-shaped controls such as choosers, chip boxes, and segmented toggles).
**Rationale**: Centralizing the shell class means a single edit updates the shell appearance everywhere it is used, keeping every field-shaped control visually consistent without each one re-declaring the same classes.
**Approved**: pending

**Decision**: Theme all color values through `apt-*` Tailwind utility classes mapped to Material Design 3 role variables injected by `<AdhThemeStyle/>`.
**Rationale**: This allows light/dark theme adaptation and token updates without changing component code, and aligns with the Material Design 3 system's color-role-based approach.
**Approved**: pending

**Decision**: Apply `min-w-0` to override the default `min-width: auto` flex/grid item behavior.
**Rationale**: Without it, long text or wide content would push the container wider than intended in flex/grid layouts; this is a necessary constraint for predictable layout in complex forms.
**Approved**: pending

**Decision**: Use a dual visual indicator (border color change plus an outer ring) for both the focus-visible and invalid states.
**Rationale**: The ring adds visual depth and makes the state change visible even where a border-color change alone would be subtle. It does not, by itself, distinguish focus from invalid for a user who cannot perceive the gold/red hue difference — that distinction is currently carried by color (hue) alone, with `aria-invalid` providing the corresponding non-visual signal to assistive technology.
**Approved**: pending

