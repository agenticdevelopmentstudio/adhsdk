
- **Screen container**: Component renders within the shared `Screen` ingredient (a `<section>` by default) carrying `id="tour"`. Without an accessible name (`aria-label` or `aria-labelledby`), this section is not exposed to assistive technology as a landmark region — see Compliance.
- **Semantic navigation**: Navigation links use standard `<a>` elements with `href` attributes; not marked as buttons. They sit inside a plain `<div className="lp-tour__steps">`, not a `<nav>` landmark, so assistive technology reaches them as ordinary links rather than through a named navigation region.
- **Arrow decorative status**: Left and right arrow characters are marked `aria-hidden="true"` as they are visual indicators duplicating semantic link content
- **Label clarity**: Callers SHOULD supply step labels (the `<b>` text) that name the destination; the component renders the text it is given and cannot check it.
- **Note clarification**: Callers SHOULD supply note text (the `<em>` text) that says what the reader gains by following the link; the component renders it as given.
- **Pillar structure**: Pillar cards render with semantic heading (`<h3>`) and paragraph (`<p>`) to convey structure to assistive technology
- **Heading outline**: Pillar cards use a fixed `<h3>`, but the screen renders no `<h1>` or `<h2>` above them (the promise is a `<p>`), so the heading outline skips levels unless the host page supplies the higher headings. Heading level is not configurable.
- **Eyebrow context**: Eyebrow text provides step progress context to all users
- **Touch targets**: This ingredient sets no touch-target minimum for inline links that might appear inside `promise` content — that's the caller's typography choice. The back/next step links this component renders are block-level anchors; the source does not specify their spacing, which is controlled entirely by CSS.

