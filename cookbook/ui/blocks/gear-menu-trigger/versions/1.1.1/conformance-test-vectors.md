
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| gear-001 | gear-icon, dropdown-trigger | Render with `label="Test"` | Settings icon (14px) is rendered and is `aria-hidden`; component is a clickable/activatable trigger |
| gear-002 | aria-label | Render with `label="Registry actions"` | `aria-label="Registry actions"` is set on the trigger element |
| gear-003 | required-label | Attempt to render without `label` prop | TypeScript compiler error (missing required prop) |
| gear-004 | disabled-state, disabled-opacity | Render with `disabled={true}` | Trigger element has `disabled` attribute; opacity is 40% |
| gear-005 | disabled-state | Render with `disabled={true}` and attempt to click/activate | Trigger does not respond to interaction (native `disabled` behavior) |
| gear-006 | class-override | Render with `className="custom-class"` | Custom class is applied to the trigger element alongside default styles |
| gear-007 | icon-aria-hidden | Render and inspect icon element | Icon has `aria-hidden="true"` |
| gear-008 | focus-indicator | Render and inspect trigger element (not focused) | `outline: none` is applied (no browser outline visible) |
| gear-009 | hover-color | Render and hover over trigger | Text color changes from `text-apt-text-dim` to `text-apt-text` |
| gear-010 | focus-indicator | Render and focus via keyboard | 2px gold/40 focus ring is visible around the 24px square, serving as the sole focus indicator |

