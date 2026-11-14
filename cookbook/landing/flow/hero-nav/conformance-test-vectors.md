
Vectors derive from `hero-nav.test.tsx` in the landing package's `__tests__` folder, where a test is named.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hero-nav-001 | nav-landmark, nav-label, link-per-row, link-order, link-href, link-text | Test "is a labelled nav of plain anchors, one per row, in order": rows `#work` Work and `#contact` Contact, label "Sections" | `nav.lp-hero-nav` has `aria-label` "Sections"; two `a.lp-hero-nav__link` give href and text `#work`/Work then `#contact`/Contact. |
| hero-nav-002 | separator-between, separator-hidden | Test "draws a hidden separator between rows and none at the ends": three rows | Two `.lp-hero-nav__sep` elements, each `aria-hidden="true"`. |
| hero-nav-003 | no-edge-separators | Same test, three rows | The nav's first and last element children both have class `lp-hero-nav__link`. |
| hero-nav-004 | lens-selector, lens-colors | Test "sweeps its links with the lens, from the dim ink to the bright accent": render with two rows | The most recent lens call has selector `.lp-hero-nav__link`, `fromColor` `--lp-ink-dim`, `toColor` `--lp-accent-bright`. |
| hero-nav-005 | client-only | Test "ships from the client barrel only": import both barrels | `client.HeroNav` is the component; `'HeroNav' in server` is false. |
| hero-nav-006 | phone-separators, phone-gap | Test "drops its separators at phone width, where the row wraps": parse `flow.css`, read the `(max-width: 640px)` media rules | `.lp-hero-nav__sep` has `display: none`; `.lp-hero-nav` has `column-gap: 1.2rem`. |
| hero-nav-007 | mono-font | Test "is set in the kit mono": read the `.lp-hero-nav {` rule | It contains `font-family: var(--lp-font-mono, ui-monospace, "SF Mono", monospace);`. |
| hero-nav-008 | link-per-row, separator-between | Test "is styled by the kit: flow.css carries its rules": read `flow.css` | It contains the rules `.lp-hero-nav {`, `.lp-hero-nav__sep {`, `.lp-hero-nav__link {`. |
| hero-nav-009 | link-per-row, no-edge-separators | Failure mode: `rows` is `[]` | The nav renders with its `aria-label` and no links or separators; the lens finds no elements and starts nothing. |
| hero-nav-010 | separator-between, no-edge-separators | One row only | One link and no separator. |

The `lens-delay`, `lens-reduced-motion`, `plain-anchors`, `focus-ring` and `hover-color` requirements have no automated vector in the test file. `lens-delay` is checkable by inspecting the options the lens receives (`startDelay: 2000`); the remaining four are verified by reading the source and `flow.css`. The `separator-drawn` SHOULD is a construction rule and has no test.

