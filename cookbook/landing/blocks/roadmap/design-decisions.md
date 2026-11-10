
**Decision**: Omit the eyebrow `<span className="lp-eyebrow">` entirely when the `eyebrow` prop is `undefined`, rather than rendering an empty element.
**Rationale**: Structural separation should be visible and intentional — a reader who sees the eyebrow knows the section is labeled, and its absence means there is no label. An invisible empty span would create a layout gap the HTML source cannot explain, making the component harder to debug and test.
**Approved**: pending

**Decision**: The component does not validate or transform child content; it simply wraps `children` as given.
**Rationale**: Parent components are responsible for ensuring children are appropriate for a roadmap section; adding validation here would duplicate concerns owned by the caller.
**Approved**: pending

**Decision**: The eyebrow span carries no ARIA role or label association (no `role="group"`/`aria-labelledby`) tying it to the children that follow.
**Rationale**: The eyebrow is a decorative visual label styled via `.lp-eyebrow`, not a heading or landmark; treating a bare `<span>` as one would overstate its semantics. Screen reader users encounter the eyebrow's own text (when present) and the children as ordinary sibling content within the `.lp-roadmap` div.
**Approved**: pending

