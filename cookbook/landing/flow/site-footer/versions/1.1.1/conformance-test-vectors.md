
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| site-footer-001 | render-footer-landmark | Render component with no props | Output contains a `<footer>` element |
| site-footer-002 | apply-lp-site-foot-class | Render component with no props | Footer element's `class` attribute contains `lp-site-foot` |
| site-footer-003 | accept-children | Render with `children="Footer content"` | Footer element contains text "Footer content" |
| site-footer-004 | wrap-children-in-layout-column | Render with children | Footer's direct child is a `<div>` with class `lp-wrap`, and that `div` contains the children |
| site-footer-005 | merge-classes | Render with `className="custom-footer"` | Footer element's `class` attribute is exactly `lp-site-foot custom-footer` |
| site-footer-006 | merge-classes | Render with `className={undefined}` | Footer element's `class` attribute is exactly `lp-site-foot` |
| site-footer-007 | merge-classes | Render with `className=""` | Footer element's `class` attribute is exactly `lp-site-foot` (empty string is falsy and filtered) |
| site-footer-008 | apply-footer-chrome | Render component | Footer element's computed style has a `1px` top border, `background-color` equal to the `--lp-ground` token, `color` equal to the `--lp-ink-dim` token, and `font-size: 0.86rem` |
| site-footer-009 | apply-footer-chrome | Render component with `--lp-dock-clear` set to a non-zero value on an ancestor | Footer element's computed `padding-bottom` equals `clamp(3rem, 6vw, 5rem)` plus the `--lp-dock-clear` value |
| site-footer-010 | style-descendant-links | Render with `children={<a href="#">Credit</a>}` | Descendant `<a>` element's computed style has no underline text-decoration, a `1px` bottom border, and `color` equal to the `--lp-ink` token |
| site-footer-011 | style-credit-sub-lines | Render with `children={<small>© 2026</small>}` | Descendant `<small>` element's computed `font-size` is `0.72rem` |

