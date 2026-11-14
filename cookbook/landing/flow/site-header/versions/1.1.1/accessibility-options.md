
- **Reduce Motion**: Not applicable; SiteHeader does not animate. Scrolling behavior is provided by the browser. NavChrome handles Reduce Motion for its drawer animations.
- **Increase Contrast**: SiteHeader has no Increase-Contrast-specific behavior, but it is not colorless: `flow.css` sets the inline nav links' own text color and hover color directly (see **Link styling**), rather than inheriting from `NavChrome` or the parent.
- **Differentiate Without Color**: Not applicable; SiteHeader does not use color as a sole means of conveying information.

