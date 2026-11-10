
**Decision**: Use a continuous pulsing opacity animation rather than background-color shifts or position changes.
**Rationale**: Opacity pulsing is a simple, performant animation that does not distort layout.
**Approved**: pending

**Decision**: Provide no built-in width or height; sizing is left entirely to the consumer via `className` or inline styles.
**Rationale**: Keeps the component flexible across use cases (e.g. a small avatar skeleton vs. a large content block) without the component needing to know the shape of what it stands in for.
**Approved**: pending

**Decision**: The component sets no ARIA role and does not apply `aria-hidden` itself; a consumer opts in via **aria-hidden-while-loading** (`aria-hidden="true"` on the skeleton, `aria-busy="true"` on the parent).
**Rationale**: The skeleton is a purely visual placeholder with no semantics of its own; composing the loading announcement belongs to the container that knows what content is loading, using the html-passthrough mechanism the component already provides.
**Approved**: pending

**Decision**: The pulsing animation is not suppressed automatically under the user's reduced-motion preference; a consumer opts in via a `motion-reduce:animate-none` override in `className`.
**Rationale**: The source does not read `prefers-reduced-motion` itself, but class-merge (backed by `clsx` and `tailwind-merge`) preserves a variant-scoped override alongside the built-in `animate-pulse` class, so the capability exists without changing the component's default appearance.
**Approved**: pending

