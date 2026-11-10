
| ID | Requirements | Input | Expected |
|----|----|----|----|
| hero-001 | render-headline | `headline="Claim"` | An `<h1>` containing the text "Claim" renders |
| hero-002 | render-tagline | `tagline="Supporting text"` | A `<p class="lp-tag">` containing "Supporting text" renders |
| hero-003 | accept-mark | `mark={<img src="logo.svg" />}` | The mark element renders before the `<h1>` |
| hero-004 | accept-children | `children={<button>CTA</button>}` | The CTA button renders after the tagline |
| hero-005 | support-glow | `glow={true}` | A decorative glow element (`aria-hidden`, no content) renders behind the mark and headline |
| hero-006 | support-glow | `glow={false}` | No glow element renders |
| hero-007 | support-id | `id="hero-section"` | The root element has `id="hero-section"` |
| hero-008 | center-content | Any props | Content renders horizontally centered within the screen |
| hero-009 | render-as-div | Any props | The root element is a non-semantic container (`<div>` on web), never a `<section>` |
| hero-010 | hero-styling-class | Any props | The root carries the hero's own styling identity (`lp-hero` on web) in addition to the generic screen styling |
| hero-011 | accept-mark (edge case: mark omitted) | `mark` undefined | No mark element renders; the `<h1>` and `<p class="lp-tag">` still render as normal |
| hero-012 | accept-children (edge case: children omitted) | `children` undefined | Nothing renders after the tagline |
| hero-013 | render-headline, render-tagline (edge case: empty strings) | `headline=""`, `tagline=""` | An empty `<h1>` and an empty `<p class="lp-tag">` render; no error is thrown |
| hero-014 | render-headline (edge case: nested ReactNode) | `headline={<>Claim <b>emphasized</b></>}` | The nested markup renders inside the `<h1>` unchanged |
| hero-015 | accept-children (edge case: multiple children) | `children={<><Cta/><Trust/><StatusPill/></>}` | All three render, in the given order, after the tagline |
| hero-016 | support-glow (edge case: glow omitted) | `glow` undefined | Same as hero-005: the glow element renders by default |
| hero-017 | render-tagline (edge case: tagline must be phrasing content) | `tagline={<em>Emphasis</em>}` | The inline content renders nested inside the `<p>`; block-level content (e.g. a `<div>`) is out of contract and produces invalid, browser-auto-corrected HTML |

