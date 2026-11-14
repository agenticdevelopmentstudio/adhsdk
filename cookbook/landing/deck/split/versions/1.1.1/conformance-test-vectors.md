
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| split-001 | renders-children | Two `<div>` children | Both children rendered in DOM |
| split-002 | root-class | No `className` prop | Root element has class `lp-split` |
| split-003 | merges-classname | `className="custom-class"` | Root element has both `lp-split` and `custom-class` in its `classList` (order not asserted; verified via `classList.contains`, not string equality) |
| split-004 | responsive-breakpoint | Playwright, viewport 900px then 1024px (bracketing the `62rem`/992px breakpoint) | Computed `grid-template-columns` changes from a single track to two tracks in a `5:6` ratio; jsdom cannot evaluate the media query, so this vector runs only in Playwright |
| split-005 | preserves-reading-order | Two `<div>` children, inspected at both breakpoint states | Root element has no `role` attribute; each child's DOM order matches its visual order |
| split-006 | responsive-breakpoint | Playwright, viewport ≥992px, `dir="rtl"` on an ancestor | The first child's bounding box is to the right of the second child's — native CSS Grid direction-aware mirroring, since `css/base.css` sets no explicit `direction` override |
| split-007 | merges-classname | `className={undefined}`, then `className=""` | Root `classList` is exactly `['lp-split']`; the `class` attribute string has no leading/trailing whitespace and no empty token |
| split-008 | renders-children | No children | Root renders with class `lp-split` and zero child DOM nodes; no error thrown |
| split-009 | renders-children | One `<div>` child | Child renders normally; `grid-template-columns` is unaffected by child count at either breakpoint state |
| split-010 | responsive-breakpoint | Playwright, viewport 2560px | Column widths remain in a `5:6` ratio (`minmax(0, 5fr) minmax(0, 6fr)`); no `max-width` is applied |
| split-011 | responsive-breakpoint | Playwright, viewport 320px | Single-column stack; no horizontal overflow/scrollbar |

