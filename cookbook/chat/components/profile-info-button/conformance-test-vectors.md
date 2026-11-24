
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| profile-info-button-001 | link-destination | From `ProfileInfoButton.test.tsx` ("links to the profile in a new tab with the accessible label"): render with `profileUrl="https://registry.example/olylo"` and `label="olylo's profile"` | The link found by role "link" has `href` equal to `https://registry.example/olylo`. |
| profile-info-button-002 | new-tab, opener-isolation | Same render | The link has `target="_blank"` and `rel="noopener noreferrer"`. |
| profile-info-button-003 | accessible-name, tooltip | Same render | The link is found by role "link" with accessible name `olylo's profile`, and its `title` is `olylo's profile`. |
| profile-info-button-004 | root-class, glyph | Same render | The link has class `pc-profile-info` and its text content is `i`. |
| profile-info-button-005 | glyph-hidden | Same render | The only child is a span with `aria-hidden="true"` containing `i`. |
| profile-info-button-006 | extra-class | Render with `className="host-extra"` | The class attribute is `pc-profile-info host-extra`. |
| profile-info-button-007 | extra-class | Render without `className`, and again with `className=""` | The class attribute is exactly `pc-profile-info` in both cases, with no trailing space. |
| profile-info-button-008 | placement, size | Render in a `position: relative` wrapper with the stylesheet and no custom properties | The circle's declared width and height are 22px and its center is 21px from the wrapper's left edge and on its top edge. |
| profile-info-button-009 | placement, size, glyph-scale | Set `--pc-pi-size: 30px` and `--pc-pi-inset: 40px` on the wrapper | The circle's declared width and height are 30px, its center is 40px from the left edge, and the glyph font size is 18px. |
| profile-info-button-010 | theme-tokens, opaque-face | Render in a wrapper with none of the `--pc-*` tokens defined | Face `#050805`, glyph `#d0d0d0`, border `rgba(255, 255, 255, 0.35)`, font monospace. |
| profile-info-button-011 | hover-focus-highlight | Hover the button, then separately Tab to it | In both cases the border color equals the glyph color and a box shadow is present; no outline is drawn. |
| profile-info-button-012 | memoized | Re-render the host with identical `profileUrl`, `label` and `className` | The inner render function does not run again. |
| profile-info-button-013 | host-placement | Render the button inside `.persona-chat` (`overflow: hidden`) | The upper half of the circle is clipped, which is the failure the host must avoid. |
| profile-info-button-014 | link-destination | Render with `profileUrl=""` | An anchor is rendered with an empty `href`; the component does not hide itself (the host guard is what omits it). |

Vectors 001 to 007, 012 and 014 are asserted in `ProfileInfoButton.test.tsx`; 008 to 011 and 013 are `it.skip` there because jsdom cannot exercise stylesheet layout, `var()` fallbacks, `:hover`/`:focus-visible` or overflow clipping. `highlight-transition`, `no-decoration` and `stacking` have no vector because they are visual-only rules checked by inspection of the stylesheet.
