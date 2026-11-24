
| ID | Requirement | Input | Expected |
|----|-------------|-------|----------|
| screen-001 | render-children | `children: <p>Content</p>` | Element tree includes the `<p>` element |
| screen-002 | render-semantic-element | `as: 'section'` or omitted | Root element is `<section>` |
| screen-003 | render-semantic-element | `as: 'div'` | Root element is `<div>` |
| screen-004 | apply-base-class | Any props | Root element has `lp-screen` in its class list |
| screen-005 | center-alignment | `align: 'center'` | Root element has both `lp-screen` and `lp-screen--center` in class list |
| screen-006 | center-alignment | `align: 'top'` or omitted | Root element has `lp-screen` class but not `lp-screen--center` |
| screen-007 | merge-classname | `className: 'custom-class'` | Root element has `lp-screen` and `custom-class` in class list |
| screen-008 | merge-classname | `className: 'lp-screen extra'` | Root element's class attribute contains `lp-screen` twice (e.g. `lp-screen lp-screen extra`); a DOM `classList` treats the duplicate token as a no-op |
| screen-009 | render-glow | `glow: true` | First child of root element is the Glow component |
| screen-010 | render-glow | `glow: false` or omitted | No Glow component is rendered |
| screen-011 | render-glow | `glow: true, children: null` | First child of root element is still the Glow component; Glow's presence does not depend on `children` |
| screen-012 | accept-id | `id: 'slide-1'` | Root element has `id="slide-1"` |
| screen-013 | snap-point-viewport-height | Any props | The `lp-screen` class's computed style resolves to `min-height: 100vh` and `scroll-snap-align: start` |
| screen-014 | render-children | `children: null` or `children: undefined` | Root element renders with no additional content beyond any Glow output |
| screen-015 | render-children | `children: []` (empty array) | Root element renders with no additional content, same as `null` or `undefined` |

