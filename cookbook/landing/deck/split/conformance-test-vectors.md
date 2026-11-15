
| ID | Requirement | Input | Expected |
|----|-------------|-------|----------|
| split-001 | renders-children | `children: <p>Copy</p>` and `<p>Shot</p>` | Both `<p>` elements are rendered inside the root element, in the order given |
| split-002 | root-class | Any props | Root element is a `<div>` with `lp-split` in its class list |
| split-003 | merges-classname | `className: 'custom'` | Root element's class attribute is exactly `lp-split custom` |
| split-004 | responsive-breakpoint, viewport-resize | The `.lp-split` rules in `packages/web/packages/landing/src/css/base.css` | The base rule declares `display: grid` and no `grid-template-columns` (single column); a `@media (min-width: 62rem)` rule declares `grid-template-columns: minmax(0, 5fr) minmax(0, 6fr)` and `gap: 3rem`; the base gap is `2rem`. jsdom does not apply stylesheets or media queries, so check it by parsing `base.css`; actually resizing the viewport needs a real browser |
| split-005 | preserves-reading-order | Any props | Root element has no `role` attribute, and no `.lp-split` rule in `base.css` declares `order` or `row-reverse` |
| split-006 | responsive-breakpoint | Component rendered under an ancestor `dir="rtl"` at or above `62rem` | The first child sits in the right-hand column and the second in the left-hand column. Needs real layout, which jsdom does not compute; run it in a browser |
| split-007 | merges-classname | `className: undefined` or `className: ''` | Root element's class attribute is exactly `lp-split`, with no empty token or trailing whitespace |
| split-008 | renders-children | No children | Root element is an empty `lp-split` container with no child nodes; no error is thrown |
| split-009 | renders-children | One child `<p>Only</p>` | The `<p>` is rendered inside the root element, which has no other children |
| split-010 | responsive-breakpoint | The `.lp-split` rules in `base.css` | No rule for `.lp-split` declares `max-width` or `width`; the column tracks are `fr`-based. Check it by parsing `base.css` |
| split-011 | responsive-breakpoint | The `.lp-split` rules in `base.css` | No rule for `.lp-split` declares `min-width`, and the only `grid-template-columns` sits inside the `62rem` media query, so below it the grid is a single column. Check it by parsing `base.css` |
