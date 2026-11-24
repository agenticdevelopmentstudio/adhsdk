
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| btn-001 | renders-anchor | `<Btn href="/path">Click</Btn>` | DOM element is an `<a>` tag |
| btn-002 | supports-href | `href="/signup"` | Rendered `<a>` has `href="/signup"` |
| btn-003 | supports-children | `children="Sign up now"` | Anchor text content is exactly "Sign up now" |
| btn-004 | supports-variant-prop, applies-variant-class | `variant="ghost"` | Anchor `className` is exactly `"lp-btn lp-btn--ghost"` |
| btn-005 | default-variant, applies-variant-class | No `variant` prop | Anchor `className` is exactly `"lp-btn lp-btn--primary"` |
| btn-006 | applies-btn-class | Any valid props | Anchor `className` includes `lp-btn` |
| btn-007 | supports-variant-prop, applies-variant-class | `variant="primary"` (explicit) | Anchor `className` is exactly `"lp-btn lp-btn--primary"` |
| btn-008 | applies-variant-class | `variant` forced past its type to an unsupported string (e.g. `variant={'invalid' as any}`) | Anchor `className` is exactly `"lp-btn lp-btn--invalid"`; no fallback to `primary` occurs |
| btn-009 | no-extra-props | An unrelated prop forced past the type (e.g. `target="_blank"` cast onto the props object) | Rendered `<a>` has no `target` attribute; only `class` and `href` are present |
| btn-010 | supports-children | `children=""` | Anchor renders with no visible text content; the anchor element is still present and navigable |
| btn-011 | supports-href | `href` forced past its type to `undefined` | Anchor's `href` attribute is absent; the link is present but non-functional |

