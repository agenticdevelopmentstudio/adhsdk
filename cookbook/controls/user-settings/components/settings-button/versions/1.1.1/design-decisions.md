
**Decision**: Extend `ButtonHTMLAttributes<HTMLButtonElement>` (minus `children`) and pass all rest props through to the rendered `<button>`, rather than defining a narrow, enumerated prop interface.
**Rationale**: Lets consumers use any native button capability (data attributes, ARIA, event handlers) without the component needing to enumerate them, keeping the component decoupled from visual design decisions.
**Approved**: pending

**Decision**: Style entirely through CSS class names (`aws-button`, `aws-button--{variant}`) rather than inline styles or a styling library; the `variant` prop is a convenience that encodes the `aws-button--{variant}` naming convention while still permitting direct `className` manipulation for advanced customization.
**Rationale**: Keeps the component decoupled from visual design decisions and lets consuming teams define variants in their own stylesheets under the toolkit's `aws-` CSS namespace.
**Approved**: pending

**Decision**: Default the `type` attribute to `'button'` rather than inheriting the native HTML default (`'submit'`).
**Rationale**: Prevents accidental form submission when the button is rendered outside an explicit form context, while still letting consumers override it via the `type` prop.
**Approved**: pending

**Decision**: Omit `children` from the `ButtonHTMLAttributes` extension (`Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'children'>`) and declare it as an explicit, typed component prop instead.
**Rationale**: Avoids a type conflict between the HTML attribute's `children` typing and the component's own `ReactNode` children parameter; this is a type signature concern rather than a runtime behavior, so it has no separate runtime test vector (see conformance test vector settings-button-012 for the analogous type-level check on `closed-variant-set`).
**Approved**: pending

