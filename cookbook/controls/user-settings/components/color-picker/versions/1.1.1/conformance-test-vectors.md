
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| color-001 | render-label | label="Choose Color" | Label element rendered with matching htmlFor |
| color-002 | accept-value | value="#FF0000" | Input value normalized and set to "#ff0000" |
| color-003 | fire-change | User selects RGB (0, 255, 0) from the picker | onChange callback invoked with "#00ff00" |
| color-004 | render-hex-display | value="#FF0000" | Hex text "#FF0000" (the raw `value` prop, unchanged) displayed next to picker |
| color-005 | support-disabled | disabled={true} | Input is disabled and not interactive; onChange is not invoked |
| color-006 | render-hint | hint="Select brand color" | Hint text is rendered in the field |
| color-007 | generate-id | No id prop supplied | Unique id generated and applied to input |
| color-008 | hide-hex-from-assistive-tech | Any state | Hex display has aria-hidden="true" |
| color-009 | accept-classname | className="custom-class" | Custom class applied to container div |

