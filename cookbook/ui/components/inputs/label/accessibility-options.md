
Label responds only to the native disabled state of peer elements, which is handled by the form control itself. Reduce Motion and Differentiate Without Color do not apply, because the component has no animation and conveys no state by color alone. Two options are expected of consumers and ports:

- **Dynamic Type**: Label text SHOULD scale with the system or browser text size. The 14px default is expressed in `rem` so it follows the root font size.
- **Increase Contrast**: The primary text color token SHOULD resolve to the theme's high-contrast value when the system requests increased contrast. The source delegates this to the theme (see the partial `contrast-ratio` row in Compliance).

