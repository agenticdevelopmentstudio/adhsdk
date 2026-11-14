
| State | Appearance change |
|---|---|
| Closed (default) | Only the outline trigger button is shown; no popover content in the DOM |
| Trigger hover/focus | Standard outline-Button hover + gold focus ring (`focus-visible`) |
| Open | `aria-expanded="true"` on the trigger; the portalled popover lists the syntax |
| Dismissed (Escape / outside-click) | Popover unmounts; focus returns to the trigger |

