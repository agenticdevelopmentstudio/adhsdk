
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| orb-row-001 | render-orb-links | sites=[{id:"a",url:"https://site-a.com",name:"Site A",emoji:"🅰",iconGradient:"linear-gradient(...)"}] | Rendered `<a href="https://site-a.com">` element |
| orb-row-002 | set-navigation-role | (default) | Root element has `role="navigation"` and `aria-label="Agentic family"` |
| orb-row-003 | apply-current-state, set-aria-current | currentSite="a", sites with id "a" | The link for site "a" (matched by its `href`) has class `is-current` and `aria-current="page"`; other links lack both. |
| orb-row-004 | apply-gradient-background | sites=[{...iconGradient:"linear-gradient(to right, #ff0000, #0000ff)"}] | Link's style attribute includes `background: linear-gradient(to right, #ff0000, #0000ff)` |
| orb-row-005 | render-emoji-hidden | sites=[{emoji:"🎯"}] | Emoji renders inside `<span aria-hidden="true">🎯</span>`; querying the link's accessible name via the accessibility tree does not include the emoji glyph. |
| orb-row-006 | render-tooltip-role | sites=[{name:"Example"}] | Site name renders in `<span role="tooltip">Example</span>` |
| orb-row-007 | render-indicator-when-current | currentSite="x", sites with id "x" | Indicator `<span class="orb-row-here" aria-hidden="true"></span>` rendered inside current link |
| orb-row-008 | set-docked-class | docked=true | Root element includes `is-docked` class |
| orb-row-009 | apply-custom-class | className="custom-class" | Root element includes `custom-class` in its class list |
| orb-row-010 | set-link-label | sites=[{name:"Example"}] | Link has `aria-label="Example"` |
| orb-row-011 | set-aria-current | currentSite=null or not in sites list | No link has `aria-current` set |
| orb-row-012 | render-focus-indicator | orb link receives keyboard focus | Link matches `:focus-visible`; computed `animation-play-state` is `paused`, `box-shadow` is `0 6px 18px rgba(0,0,0,0.45)` and the outline is `none` |
| orb-row-013 | show-tooltip-on-focus | orb link receives keyboard focus | Tooltip span's computed `opacity` is `1`, matching the hover-revealed state |
| orb-row-014 | apply-current-state | sites=[] | Root element renders with role="navigation" and no `<a>` children; no error |
| orb-row-015 | apply-custom-class | className="" | Root class list is `orb-row` with no empty token |
| orb-row-016 | set-docked-class | docked=false, then docked undefined | Neither render has the `is-docked` class |
| orb-row-017 | apply-current-state | Two sites share id "a", currentSite="a" | Both links have `is-current` and `aria-current="page"` |
