
**Decision**: TextField is a fully controlled component; the caller MUST manage the `value` state and invoke `onChange` to update it.
**Rationale**: This pattern requires more boilerplate but provides explicit control and integrates cleanly with form libraries and state management.
**Approved**: pending

**Decision**: When no `id` is provided, React's `useId` hook generates a unique ID for the label-input pair.
**Rationale**: `useId` is stable across a component's own renders and exists specifically to produce IDs that match between server and client during SSR hydration, so label association works without caller intervention.
**Approved**: pending

**Decision**: The component uses `noAutofillPropsFor(autoComplete)` to conditionally apply six autofill-prevention attributes (`autoComplete: 'off'`, `data-form-type: 'other'`, `data-1p-ignore: 'true'`, `data-lpignore: 'true'`, `data-bwignore: 'true'`, `data-protonpass-ignore: 'true'`). The helper trims and lowercases `autoComplete` and applies the six attributes whenever the result is `undefined` or `'off'`; any other value is treated as a real token and withholds all six.
**Rationale**: This preserves password manager integration when a real autofill token is passed, but prevents unwanted autofill in generic fields by default. There is no enumerated allowlist of tokens — any non-`'off'` value is honored, so the caller is responsible for passing a token the browser recognizes (`email`, `tel`, `url`, `name`, etc.).
**Approved**: pending

**Decision**: `SecureTextField` does not accept an `autoComplete` prop; `type="password"` and the full `noAutofillProps` set are always applied and are not configurable.
**Rationale**: Password managers should never save settings secrets (API keys, tokens) as the website's password; this is a security-first design decision.
**Approved**: pending

**Decision**: The component uses a boolean `multiline` prop rather than a separate `TextArea` component.
**Rationale**: This reduces component count and makes the two variants feel like a single configurable entity, though it does add a branching render path.
**Approved**: pending

**Decision**: When `multiline` is `true`, the textarea has a hardcoded `rows={4}`.
**Rationale**: This provides a reasonable default but may not suit all use cases; callers can override via CSS (setting the `height` property).
**Approved**: pending

**Decision**: The hint is rendered as a plain `<p>` element without explicit ARIA association (e.g., `aria-describedby`).
**Rationale**: The component owns both the input's `id` and the hint element, so this is a component-level gap rather than something a caller can complete externally — callers needing this association currently have no way to add it through this component's props.
**Approved**: pending

