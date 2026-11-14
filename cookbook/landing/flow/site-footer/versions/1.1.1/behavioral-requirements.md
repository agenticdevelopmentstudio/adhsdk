
- **render-footer-landmark**: Component MUST render an HTML `<footer>` element.
- **apply-lp-site-foot-class**: Component MUST apply the CSS class `lp-site-foot` to the footer element.
- **accept-children**: Component MUST accept and render ReactNode children.
- **wrap-children-in-layout-column**: Component MUST wrap children in a Wrap component to provide constrained layout.
- **accept-custom-class**: Component MAY accept an optional `className` prop to apply additional CSS classes.
- **merge-classes**: When a custom `className` is provided, component MUST apply both `lp-site-foot` and the custom class name to the footer element, separated by a space, and MUST filter out falsy values (`className={undefined}`, `className={false}`, or `className=""`); it does not trim whitespace-only strings and performs no de-duplication.
- **apply-footer-chrome**: Component's stylesheet (`.lp-site-foot`) MUST set its own vertical padding (`clamp(3rem, 6vw, 5rem)` top; the same value plus `var(--lp-dock-clear, 0px)` on the bottom), a `1px` top hairline border, a `var(--lp-ground)` background, `var(--lp-ink-dim)` text color, and a `0.86rem` font size — none of this is inherited from `Wrap` or from descendants.
- **style-descendant-links**: Component's stylesheet MUST style descendant `<a>` elements (`.lp-site-foot a`) with a non-default link color (`var(--lp-ink)`), no text-decoration underline, and a hairline bottom border, plus a hover state that swaps the border color to `var(--lp-accent)`, so a host's footer links never fall back to the browser's default blue underline against the dark ground.
- **style-credit-sub-lines**: Component's stylesheet MUST style descendant `<small>` elements (`.lp-site-foot small`) with a reduced font size (`0.72rem`) and letter-spacing (`0.04em`), for copyright or attribution sub-lines within a credit line.

