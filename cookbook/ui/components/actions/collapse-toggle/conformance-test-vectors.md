
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| collapse-toggle-001 | glyph-when-collapsed | `collapsed={true}, label="Topic List"` | Button displays `»` glyph |
| collapse-toggle-002 | glyph-when-expanded | `collapsed={false}, label="Topic List"` | Button displays `«` glyph |
| collapse-toggle-003 | aria-label-text | `collapsed={true}, label="Topic List"` | `aria-label="Expand Topic List"` |
| collapse-toggle-004 | aria-label-text | `collapsed={false}, label="Topic List"` | `aria-label="Collapse Topic List"` |
| collapse-toggle-005 | aria-expanded-state | `collapsed={true}` | `aria-expanded="false"` |
| collapse-toggle-006 | aria-expanded-state | `collapsed={false}` | `aria-expanded="true"` |
| collapse-toggle-007 | title-attribute-text | `collapsed={true}, label="Items"` | `title="Expand Items"` |
| collapse-toggle-008 | button-type | Any props | `type="button"` on element |
| collapse-toggle-009 | click-invokes-on-toggle | User clicks button | `onToggle` callback invoked with click event |
| collapse-toggle-010 | forwarded-click-event | User Ctrl+clicks button | `onToggle` callback receives event with `ctrlKey=true` |
| collapse-toggle-011 | aria-controls-optional | `controls="item-list"` | `aria-controls="item-list"` |
| collapse-toggle-012 | aria-controls-optional | `controls` not provided | `aria-controls` attribute is absent |
| collapse-toggle-013 | classname-merge | `className="custom-class"` | Custom class appears in rendered button className |
| collapse-toggle-014 | click-invokes-on-toggle | User focuses the button and presses Enter or Space | `onToggle` callback invoked with the resulting click event (native `<button>` key-activation behavior) |
| collapse-toggle-015 | forwarded-click-event | User ⌘-clicks the button | `onToggle` callback receives the event with `metaKey=true` |

