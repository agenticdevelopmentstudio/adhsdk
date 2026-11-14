
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| site-footer-001 | render-footer-landmark | Render component with no props | Output contains a `<footer>` element |
| site-footer-002 | apply-lp-site-foot-class | Render component with no props | Footer element's `class` attribute contains `lp-site-foot` |
| site-footer-003 | accept-children | Render with `children="Footer content"` | Footer element contains text "Footer content" |
| site-footer-004 | wrap-children-in-layout-column | Render with children | Footer's direct child is a `<div>` with class `lp-wrap`, and that `div` contains the children |
| site-footer-005 | merge-classes | Render with `className="custom-footer"` | Footer element's `class` attribute is exactly `lp-site-foot custom-footer` |
| site-footer-006 | merge-classes | Render with `className={undefined}` | Footer element's `class` attribute is exactly `lp-site-foot` |
| site-footer-007 | merge-classes | Render with `className=""` | Footer element's `class` attribute is exactly `lp-site-foot` (empty string is falsy and filtered) |
| site-footer-008 | apply-footer-chrome | Real browser (Playwright), viewport 1440px wide, default token fallbacks: render component | Footer element's computed style has a `1px` top border, `background-color` `rgb(16, 16, 16)`, `color` `rgb(160, 160, 160)`, and `font-size: 13.76px` (at a 16px root) |
| site-footer-009 | apply-footer-chrome | Real browser (Playwright), viewport 1440px wide: render component with `--lp-dock-clear: 40px` on an ancestor | Footer element's computed `padding-top` is `80px` and `padding-bottom` is `120px` |
| site-footer-010 | style-descendant-links | Real browser (Playwright), default token fallbacks: render with `children={<a href="#">Credit</a>}` | Descendant `<a>` element's computed style has no underline text-decoration, a `1px` bottom border, and `color` `rgb(237, 237, 237)` |
| site-footer-011 | style-credit-sub-lines | Real browser (Playwright), 16px root: render with `children={<small>© 2026</small>}` | Descendant `<small>` element's computed `font-size` is `11.52px` |
| site-footer-012 | style-descendant-links | Real browser (Playwright), default token fallbacks: render with `children={<a href="#">Credit</a>}` and hover the link | The link's computed `border-bottom-color` changes from the hairline color to `rgb(154, 154, 154)` (the `--lp-accent` fallback) |
| site-footer-013 | style-credit-sub-lines | Real browser (Playwright), 16px root: render with `children={<small>© 2026</small>}` | Descendant `<small>` element's computed `letter-spacing` is `0.4608px` (`0.04em` of `11.52px`) |
| site-footer-014 | mount-outside-flow | Real browser (Playwright): host renders `<Flow>` and then `<SiteFooter>` as its sibling | The `<footer>` is not a descendant of `main.lp-flow` and the accessibility tree exposes it as `contentinfo` |

