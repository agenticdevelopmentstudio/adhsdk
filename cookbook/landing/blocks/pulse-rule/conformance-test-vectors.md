
Vectors 001 to 003 and 007 to 009 are drawn from the `PulseRule` tests in `hero-nav.test.tsx` (`is an <hr> with the kit class, the caller's appended`, `ships from the server barrel, a server component, and the client barrel re-exports nothing of it` and `breathes in the accent, and rests at full strength for reduced motion`). The other vectors follow from the component and `blocks.css`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pulse-rule-001 | render-hr, kit-class, no-class-name | Render `PulseRule` with no props | The container holds an `<hr>` whose class attribute is exactly `lp-pulse-rule` (test: `is an <hr> with the kit class, the caller's appended`) |
| pulse-rule-002 | append-class-name, class-name-appended-not-replaced | Render `PulseRule` with `className="ad-hero-rule"` | The `<hr>` class attribute is exactly `lp-pulse-rule ad-hero-rule` (same test) |
| pulse-rule-003 | server-component | Import the server barrel and the client barrel | `typeof server.PulseRule` is `function`; `'PulseRule' in client` is false (test: `ships from the server barrel...`) |
| pulse-rule-004 | no-class-name | Render `PulseRule` with `className=""` | The class attribute is exactly `lp-pulse-rule`, with no trailing space |
| pulse-rule-005 | render-hr | Render `PulseRule` with no props | The container has exactly one child element and it is an `<hr>` |
| pulse-rule-006 | hairline-height, accent-gradient, breathing-animation | Read `blocks.css` | The `.lp-pulse-rule` rule sets `height: 1px`, `border: 0`, a gradient that uses `var(--lp-accent, #9a9a9a)` at 50%, and an infinite `ease-in-out` animation named `lp-pulse-rule-breathe` |
| pulse-rule-007 | breathing-animation, breathing-opacity | Read `blocks.css` | The stylesheet contains `@keyframes lp-pulse-rule-breathe` (test: `breathes in the accent, and rests at full strength for reduced motion`) |
| pulse-rule-008 | reduced-motion-rest | Read `blocks.css` | Under `@media (prefers-reduced-motion: reduce)`, `.lp-pulse-rule` sets `animation: none` and `opacity: 1` (same test) |
| pulse-rule-009 | period-property, floor-property | Render the rule with `--lp-pulse-rule-period: 12s` and `--lp-pulse-rule-floor: 0.6` set on the element | The cycle takes 12s and opacity bottoms out at 0.6; with neither set, the cycle takes 6s and the floor is 0.35 |
| pulse-rule-010 | accent-fallback | Render the rule where `--lp-accent` is undefined | The gradient's centre color is `#9a9a9a` |

