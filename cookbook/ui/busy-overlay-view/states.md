
| State | Appearance change |
|-------|------------------|
| Default (not showing) | Not in any view hierarchy; `isShowing == false`; spinner stopped and not displayed when stopped |
| Showing | Over the host at opacity 1; spinner animating; message line visible only when a non-empty message was given |
| Fading in | Opacity animates from 0 to 1 over 0.2 seconds; already swallowing input as soon as opacity is above 0 |
| Fading out | `isShowing == false`; opacity animates to 0 over 0.2 seconds; remains in the host until the fade completes; hit tests answer nothing from the moment `hide()` is called, because the opacity value is set to 0 at once |
| Pressed | Not applicable: the overlay is not interactive; every press is swallowed and nothing changes |
| Disabled | Not applicable: the overlay has no enabled or disabled state in source |
| Focused | Not applicable: the overlay is not a focusable control in source |
| Loading | The Showing state is the loading state: the spinner animates and the optional message reads what is happening |

