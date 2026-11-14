
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| switch-001 | toggles-on-click | Unchecked Switch, user clicks | State changes to checked; callback fires if controlled |
| switch-002 | toggles-on-click | Checked Switch, user clicks | State changes to unchecked; callback fires if controlled |
| switch-003 | support-controlled | Controlled Switch with `checked={true}` and `onCheckedChange`; user clicks, parent does not update `checked` | `onCheckedChange` fires with the toggled value; the rendered state stays at `checked={true}` until the parent prop changes |
| switch-004 | support-uncontrolled | Uncontrolled Switch with `defaultChecked={true}` | Clicking toggles visual state without external callback |
| switch-005 | respect-disabled-state | Disabled Switch, user clicks | State does not change; Base UI's internal disabled guard blocks the click handler (not CSS `pointer-events`) — the root shows no visual change |
| switch-006 | animate-position | Toggle checked → unchecked | Thumb translates from 14px to 0px with a smooth transition |
| switch-007 | animate-colors | Toggle checked → unchecked | Track color transitions from the checked color to the unchecked color smoothly |
| switch-008 | render-inline | Switch rendered in text flow | Component displays as inline-flex (does not break text flow) |
| switch-009 | class-prop | Switch with custom `className="my-custom-class"` | Custom class merges with internal classes; visual result reflects both |
| switch-010 | respect-disabled-state | Disabled Switch (`disabled={true}`), controlled parent flips the `checked` prop | Track color and thumb position still animate to match the new `checked` value — the transition classes are always active and unaffected by `disabled`, which shows no visual change of its own; user clicks remain ignored |
| switch-011 | toggle-on-space | Enabled Switch, user presses Tab to focus then presses Space | State toggles; callback fires if controlled |
| switch-012 | expose-switch-role | Switch rendered with an accessible name | Assistive technology reports role "switch" along with the provided name and current checked state |
| switch-013 | respect-disabled-state | Disabled Switch, focused via Tab, user presses Space | State does not change; no callback fires |
| switch-014 | toggles-on-click | Enabled Switch, user clicks 3 times in rapid succession | Each completed click toggles the state once; three clicks alternate checked/unchecked/checked with no coalesced or dropped toggles |

