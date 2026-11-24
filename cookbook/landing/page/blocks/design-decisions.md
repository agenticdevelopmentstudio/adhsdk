
**Decision**: One shared module renders blocks for both the snap deck and the continuous flow.
**Rationale**: A block that renders one way in a deck and another in a flow is the same content saying two different things; one copy removes the drift (the source's own comment).
**Approved**: pending

**Decision**: Bodies go through `prose` as `<p>` elements, never as a bare text child.
**Rationale**: The kit styles a body through its paragraph child (`.lp-card p`, `.lp-closer p`, `.lp-faq details p`); a bare child is valid JSX with the right words and the wrong pixels.
**Approved**: pending

**Decision**: A Shot with no `src` passes no `media`, and the page model supplies the default pending label `Screenshot coming soon`.
**Rationale**: The kit renders the placeholder only when `media` is absent, and `pendingLabel` has no default in the kit because it is visible copy the kit does not choose. The label is chosen here once for every page built from data, and a host with its own word passes that instead. It matches the content generator's placeholder image wording.
**Approved**: pending

**Decision**: Icon ids and screenshot ids are resolved to `/icons/<id>.svg` and `/screenshots/<id>.png` here, against the site's own origin.
**Rationale**: One image set then serves the brochure and the help site, whose Markdown sanitizer accepts only absolute http or https sources (from the `Shot` block type's comment).
**Approved**: pending

**Decision**: The unhandled-kind case is a compile-time `never` assignment, and at runtime the block value is returned unrendered.
**Rationale**: The switch is the one place that could silently drop a block from every site's page at once, so a new `kind` must fail the type check. Technical debt that affects behavior: there is no runtime guard in this module, so data that bypasses the type system comes back as an unrendered value and fails later, in React, instead of at the switch.
**Approved**: pending

**Decision**: `indexRows` omits the hero.
**Rationale**: The hero is the top of the page, which the browser's Home key already reaches; a first row meaning "go back to where you started" carries no information.
**Approved**: pending

**Decision**: Every block it renders is a server component.
**Rationale**: The module sits behind the server-safe barrel, and a build check asserts `dist/index.js` stays free of `'use client'`.
**Approved**: pending

