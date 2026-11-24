
- **render-children**: Component MUST render any children passed via the `children` prop, including rendering an empty root element without error when `children` is `null`, `undefined`, or omitted.
- **default-class**: Component MUST apply the CSS class `vp-spacer` to its root element.
- **class-composition**: Component MUST combine the default class `vp-spacer` with a custom `className` when one is provided, separating them with a single space (e.g., `vp-spacer custom-class`); an empty-string `className` MUST NOT add a trailing space, so the root element's class stays `vp-spacer`.
- **fills-remaining-space**: The `vp-spacer` class MUST set `flex: 1 1 0` and `min-height: 0`, so the root element grows to absorb leftover vertical space in a flex-column parent (a `ViewportShell`) and can still shrink below its content size.
- **root-element**: Component MUST render its root as a single `div` element.
- **assistive-tech-invisible**: Component MUST NOT add an ARIA role, an accessible label, or a tab stop to the root element, so it stays invisible to assistive technology.

