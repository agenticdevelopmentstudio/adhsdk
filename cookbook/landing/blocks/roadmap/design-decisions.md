
**Decision**: Omit the eyebrow `<span className="lp-eyebrow">` only when the `eyebrow` prop is exactly `undefined`; every other value, including `null`, `""`, `false` and `0`, still renders the span.
**Rationale**: Structural separation should be visible and intentional — a reader who sees the eyebrow knows the section is labeled, and its absence means there is no label. In the source, an omitted prop is how a caller says "no label": an empty span would take `.lp-roadmap .lp-eyebrow`'s margin and open the box with a blank line the JSX cannot explain. The check is `=== undefined` and not a nullish or empty check, so a caller who passes `null`, `""`, `false` or `0` gets the same empty span and margin; callers MUST omit the prop, not pass an empty value, when there is no label.
**Approved**: pending

**Decision**: The component does not validate or transform child content; it simply wraps `children` as given.
**Rationale**: Parent components are responsible for ensuring children are appropriate for a roadmap section; adding validation here would duplicate concerns owned by the caller.
**Approved**: pending

**Decision**: The eyebrow span carries no ARIA role or label association (no `role="group"`/`aria-labelledby`) tying it to the children that follow.
**Rationale**: The eyebrow is a visible text label, so it carries meaning for sighted readers, and it is exposed to screen readers as its own text. It is not made a heading or landmark: the `.lp-roadmap` container is a plain `div`, not a region, and an `aria-labelledby` association would turn an aside inside an already-headed section into a second named landmark. Screen reader users encounter the eyebrow's text (when present) immediately before the children, as ordinary sibling content within the `.lp-roadmap` div.
**Approved**: pending

