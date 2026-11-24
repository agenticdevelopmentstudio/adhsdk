
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| contact-001 | mail-prop, mail-link-render, semantic-link | `mail: { href: "mailto:test@example.com", label: "Email us" }` | Rendered `<a href="mailto:test@example.com">Email us</a>` element |
| contact-002 | css-classes | Any valid props | Link has class `lp-mail` |
| contact-003 | colophon-paragraph | `colophon: "© 2026 Example"` | Rendered `<p class="lp-colophon">© 2026 Example</p>` |
| contact-004 | closer-composition, title-prop, children-prop | `title: "Get in Touch"`, `children: <p>We'd love to hear from you</p>` | `Closer` receives `title` unchanged; `Closer`'s rendered children are the caller's `children`, followed by the mail link, followed by the optional colophon, in that order |
| contact-005 | colophon-paragraph | `colophon: undefined` | No colophon paragraph rendered |
| contact-006 | css-classes | Any valid props | Composed element matches the compound selector `.lp-closer.lp-contact` |
| contact-007 | link-label | `mail: { href: "mailto:test@example.com", label: "" }` | Anchor renders with empty text content; the caller has violated **link-label**, which the component does not check |
| contact-008 | mailto-scheme | `mail: { href: "https://example.com/contact", label: "Contact" }` | Anchor renders with the given `href`; the caller has violated **mailto-scheme**, which the component does not check |
| contact-009 | colophon-paragraph | `colophon: ""` | Rendered `<p class="lp-colophon"></p>` (empty paragraph present in the DOM) |
| contact-010 | closer-composition | `children: undefined` | `Closer` receives `children: undefined` unchanged |
| contact-011 | closer-composition | `title: undefined` | `Closer` receives `title: undefined` unchanged |
| contact-012 | colophon-paragraph | `colophon: null` | Rendered `<p class="lp-colophon"></p>` (empty paragraph present in the DOM), because the check is `!== undefined` |
| contact-013 | link-label | `mail: { href: "mailto:test@example.com", label: null }` | Anchor renders with no text content; the caller has violated **link-label**, which the component does not check |
