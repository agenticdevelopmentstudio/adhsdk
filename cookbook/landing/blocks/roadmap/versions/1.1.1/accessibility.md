
- **Role**: Container (implicit `div` semantics) — no explicit role required for a layout wrapper.
- **Eyebrow label**: Renders as a bare `<span className="lp-eyebrow">` with no ARIA role or label association (no `role="group"`/`aria-labelledby`) tying it to the children that follow; it is a decorative visual label, not a semantic heading or landmark (see Design Decisions). It SHOULD still be text content or an accessible ReactNode so any text it carries is exposed to assistive technology like adjacent inline text.
- **Child content**: Component does not impose accessibility requirements on children; children remain independently accessible.

