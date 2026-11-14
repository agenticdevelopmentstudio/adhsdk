
Not applicable: this module renders no markup of its own except `<p>` elements from `prose` and the `<img>` inside a Shot. All visual styling belongs to the kit components it composes.

- **Paragraph styling**: `prose` exists because the kit styles a body through its paragraph child: `.lp-card p`, `.lp-closer p` and `.lp-faq details p`. A body rendered as a bare text child inherits the page defaults instead, so the words are right and the pixels wrong.
- **Shot image**: the `<img>` has no styling of its own in this module; Shot frames it.
- **Corner radius, padding, font, colors, border, shadow, size**: not applicable; set by the composed components.

