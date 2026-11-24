
The component responds to all standard browser and system accessibility settings:

| Option | Behavior |
|--------|----------|
| Reduce Motion | The component itself defines no animation. Any consumer CSS animation applied to the disclosure triangle or the details/summary transition MUST be disabled (or reduced to an instant state change) under the `prefers-reduced-motion` media query. |
| Increase Contrast | Browsers typically apply their default `<details>` and `<summary>` styling in high-contrast modes, but this is browser-dependent. High-contrast CSS MUST ensure the disclosure button text, background, and focus indicator meet WCAG AA or AAA contrast ratios. |
| Differentiate Without Color | Disclosure state MUST NOT be indicated by color alone. The browser's default triangle or icon indicator provides a shape change; custom CSS styling MUST preserve a non-color differentiator (icon change, text decoration, etc.). |

