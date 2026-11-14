
**Decision**: State the Tailwind utility classes and `apt-*` design tokens themselves as the Appearance requirement, rather than resolving them to literal pixel or color values.
**Rationale**: The UI Card family expresses every color and size as a Tailwind utility class or an `apt-*` design token (e.g. `bg-apt-bg`, `border-apt-border`, `text-apt-text-muted`) rather than as a literal value. `packages/web/packages/ui/src/components/card.tsx` states the intent directly: "The family Card — mirrors hub's component (apt-* tokens, generous 6-unit rhythm) so the shared library and hub render identically." The token indirection is load-bearing and MUST NOT be flattened into hard-coded values; an implementation conforms by using the named token, and the concrete pixel or color value is whatever the project's Tailwind and token configuration binds to it.
**Approved**: pending

**Decision**: Document no invented accessibility behavior beyond what the source sets.
**Rationale**: The UI Card family sets no ARIA role, label association, or tap target, because it is not an interactive control in source — it is a static container. This ingredient does not invent accessibility behavior that is not present in the code (see Accessibility).
**Approved**: pending

