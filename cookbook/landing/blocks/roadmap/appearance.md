
- **Container class**: `lp-roadmap` — styling applied via CSS class
- **Eyebrow class**: `lp-eyebrow` — applied to optional label span when rendered
- **Spacing**: No inline styles; `.lp-roadmap` in `blocks.css` sets `margin-top: 2.6rem` and `padding-top: 2rem`.
- **Visual treatment**: The separation is a top rule, not a card: `border-top: 1px solid var(--lp-hairline, rgba(216, 216, 216, 0.18))`, with no box, background tint or side border, so the planned items read as a continuation of the list above rather than a competing panel.
- **Eyebrow typography**: the shared `.lp-eyebrow` style (see [adhsdk.ingredient.landing.blocks.head](cookbook:31198bb7-2270-449e-94c1-026b68d2bc81)): `0.82rem`, weight 500, `0.28em` letter-spacing, uppercase, accent-bright color, with a leading 2.2rem accent rule.
- **Inner ledes**: `.lp-roadmap .lp-lede` has `margin-bottom: 1.4rem`.

