
**Decision**: Extend `ButtonHTMLAttributes<HTMLButtonElement>` (minus `children`) and pass all rest props through to the rendered `<button>`, rather than defining a narrow, enumerated prop interface.
**Rationale**: Lets consumers use any native button capability (data attributes, ARIA, event handlers) without the component needing to enumerate them, keeping the component decoupled from visual design decisions.
**Approved**: pending

**Decision**: Style entirely through CSS class names (`aws-button`, `aws-button--{variant}`) rather than inline styles or a styling library; the `variant` prop is a convenience that encodes the `aws-button--{variant}` naming convention while still permitting direct `className` manipulation for advanced customization.
**Rationale**: Keeps the component decoupled from visual design decisions and lets the library ship the three variant styles under the toolkit's `aws-` CSS namespace; consumers customize through `className` or by overriding the `--aws-*` tokens.
**Approved**: pending

**Decision**: Default the `type` attribute to `'button'` rather than inheriting the native HTML default (`'submit'`).
**Rationale**: Prevents accidental form submission when the button is rendered outside an explicit form context, while still letting consumers override it via the `type` prop.
**Approved**: pending

**Decision**: Omit `children` from the `ButtonHTMLAttributes` extension (`Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'children'>`) and declare it as an explicit, typed component prop instead.
**Rationale**: Makes `children` an explicit, documented prop of the component. The `Omit` is redundant for typing: `ButtonHTMLAttributes` already types `children?: ReactNode` (via `DOMAttributes`), so the re-declaration changes nothing at the type level. This is a type signature concern with no runtime behavior, so it has no runtime test vector (see conformance test vector settings-button-012 for the analogous type-level check on `closed-variant-set`).
**Approved**: pending

