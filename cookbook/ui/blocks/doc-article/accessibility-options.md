
- **Reduce Motion**: The prose classes and scroll behavior do not include animations or transitions affected by the `prefers-reduced-motion` media query. Expected behavior: no additional changes needed for reduced-motion users.
- **Increase Contrast**: Prose classes inherit text and background colors from the document's theme. If the theme respects `prefers-contrast`, prose rendering will reflect increased contrast.
- **Differentiate Without Color**: Whether links in the rendered HTML are visually distinguishable without relying on color (e.g., underlined) depends on the host's prose theme and CSS; DocArticle does not enforce or guarantee this itself. The host is responsible for choosing a prose theme where such affordances are present.

