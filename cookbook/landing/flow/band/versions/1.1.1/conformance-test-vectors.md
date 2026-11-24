
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| band-001 | render-section | Render `<Band />` | Output contains a `<section>` element |
| band-002 | default-dark-tone | Render `<Band />` without tone prop | Rendered section includes class `lp-band--dark` |
| band-003 | accept-id | Render `<Band id="section-1" />` | Rendered section has `id="section-1"` |
| band-004 | support-three-tones, apply-tone-class | Render `<Band tone="soft" />` | Rendered section includes class `lp-band--soft` |
| band-005 | support-three-tones, apply-tone-class | Render `<Band tone="paper" />` | Rendered section includes class `lp-band--paper` |
| band-006 | seam-prop, seam-class-when-true | Render `<Band />` without seam prop | Rendered section includes class `lp-band--seam` |
| band-007 | omit-seam-when-false | Render `<Band seam={false} />` | Rendered section does not include class `lp-band--seam` |
| band-008 | band-base-class | Render `<Band />` | Rendered section includes class `lp-band` |
| band-009 | accept-classname | Render `<Band className="custom-class" />` | Rendered section class list includes `custom-class` |
| band-010 | wrap-children | Render `<Band><p>Content</p></Band>` | Section's direct child is a `<div>` with class `lp-wrap`, containing `<p>Content</p>` |
| band-011 | accept-id | Render `<Band />` without an id prop | Rendered section has no `id` attribute |
| band-012 | band-base-class, apply-tone-class, seam-class-when-true, accept-classname | Render `<Band tone="soft" seam={true} className="custom-class" />` | Rendered section class list includes `lp-band`, `lp-band--soft`, `lp-band--seam`, and `custom-class` |
| band-013 | accept-classname | Render `<Band className="" />` | Rendered section class list contains no empty-string entries or doubled whitespace |
| band-014 | paper-cuts-foot | Render `<Band tone="paper" seam={false} />` | Rendered section includes class `lp-band--paper` and its computed `clip-path` cuts the bottom-left vertex by `--lp-seam`, regardless of `seam` being `false` |
| band-015 | stacking-order | Render `<Band />` | Rendered section has computed `position: relative` and `z-index: 1` |
| band-016 | stacking-order | Render `<Band tone="paper" />` | Rendered section has computed `z-index: 2` |

