
- **render-hr**: The component MUST render exactly one `<hr>` element and no other element.
- **kit-class**: The `<hr>` MUST carry the class `lp-pulse-rule`.
- **append-class-name**: When a non-empty `className` is given, the component MUST append it after `lp-pulse-rule`, separated by a single space, so the class attribute is `lp-pulse-rule <className>`.
- **no-class-name**: When `className` is absent or an empty string, the class attribute MUST be exactly `lp-pulse-rule`, with no trailing space.
- **class-name-appended-not-replaced**: A caller-supplied `className` MUST NOT replace `lp-pulse-rule`.
- **no-other-props**: The component MUST accept no prop other than `className`; it takes no children and sets no inline style or attribute beyond `class`.
- **server-component**: The component MUST be exported from the server barrel and MUST NOT be exported from the client barrel.
- **hairline-height**: The rule MUST be drawn 1px tall with no border.
- **accent-gradient**: The rule's background MUST be a 90-degree linear gradient from transparent, through the accent color `--lp-accent` at 50%, to transparent, so it fades to nothing at both ends.
- **accent-fallback**: When `--lp-accent` is not defined, the rule SHOULD fall back to `#9a9a9a`.
- **breathing-animation**: The rule MUST run the `lp-pulse-rule-breathe` animation with `ease-in-out` timing, repeating indefinitely.
- **breathing-opacity**: The animation MUST hold opacity at the floor value at 0% and 100% of the cycle and at 1 at 50%.
- **period-property**: The cycle length MUST be read from `--lp-pulse-rule-period`, defaulting to 6s when the property is not set.
- **floor-property**: The opacity floor MUST be read from `--lp-pulse-rule-floor`, defaulting to 0.35 when the property is not set.
- **reduced-motion-rest**: Under `prefers-reduced-motion: reduce`, the rule MUST have no animation and MUST sit at opacity 1.
- **compositor-only-animation**: The animation SHOULD change opacity alone, never a color, so the rule can breathe indefinitely without triggering repaints.

